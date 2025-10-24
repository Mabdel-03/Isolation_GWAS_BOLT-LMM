#!/usr/bin/env python3
"""
Convert BOLT-LMM output files to MTAG format with rsID mapping.

MTAG format requires:
- snpid: rsID (from annotation file)
- chr: Chromosome
- bpos: Base pair position
- a1: Effect allele (ALLELE1)
- a2: Reference allele (ALLELE0)
- freq: Effect allele frequency
- z: Z-score (BETA/SE)
- pval: P-value (P_BOLT_LMM)
- n: Sample size
"""

import pandas as pd
import numpy as np
import os
import sys
import gzip

def load_rsid_mapping(annot_file):
    """
    Load rsID mapping from annotation file.
    Returns dict: {chr:pos:ref:alt -> rsID}
    """
    print(f"Loading rsID mapping from: {annot_file}")
    
    # Read annotation file - appears to have no header based on column output
    # Columns seem to be: CHR, POS, ID (chr:pos:ref:alt), REF, ALT, QUAL, FILTER, rsID, ...
    df_annot = pd.read_csv(annot_file, sep='\t', compression='gzip', 
                           header=None, low_memory=False)
    
    print(f"  First row (inferred structure): {list(df_annot.iloc[0, :10])}")
    print(f"  Total rows: {len(df_annot):,}")
    
    # Based on your output, the file structure appears to be:
    # Col 0: CHR (e.g., '1')
    # Col 1: POS (e.g., '756604')
    # Col 2: ID (e.g., '1:756604:A:G')
    # Col 3: REF (e.g., 'A')
    # Col 4: ALT (e.g., 'G')
    # Col 5: QUAL (e.g., 'PASS')
    # Col 6: FILTER (e.g., 'array_both')
    # Col 7: rsID (e.g., 'rs3131962')
    
    # Create variant ID from columns 0,1,3,4 (chr:pos:ref:alt)
    df_annot['variant_id'] = (df_annot[0].astype(str) + ':' + 
                               df_annot[1].astype(str) + ':' +
                               df_annot[3].astype(str) + ':' +
                               df_annot[4].astype(str))
    
    # rsID is in column 7, filter to rows where it starts with 'rs'
    df_with_rsid = df_annot[df_annot[7].astype(str).str.startswith('rs', na=False)]
    
    # Create lookup dictionary
    lookup = df_with_rsid.set_index('variant_id')[7].to_dict()
    
    print(f"  Loaded {len(lookup):,} rsID mappings")
    print(f"  Coverage: {100*len(lookup)/len(df_annot):.1f}% of variants have rsIDs")
    
    return lookup

def get_sample_size(pheno_file, pheno_col):
    """
    Get sample size (number of non-missing phenotypes) from EUR-filtered file.
    """
    df = pd.read_csv(pheno_file, sep='\t', compression='gzip')
    n = df[pheno_col].notna().sum()
    return n

def convert_bolt_to_mtag(bolt_file, rsid_lookup, trait_name, sample_size, output_file):
    """
    Convert BOLT-LMM output to MTAG format.
    """
    print(f"\nConverting {trait_name}...")
    print(f"  Input: {bolt_file}")
    print(f"  Output: {output_file}")
    print(f"  Sample size: {sample_size:,}")
    
    # Read BOLT-LMM output
    df_bolt = pd.read_csv(bolt_file, sep='\t', compression='gzip')
    print(f"  Variants in BOLT file: {len(df_bolt):,}")
    print(f"  Columns in BOLT file: {list(df_bolt.columns)}")
    
    # Determine which p-value column to use
    if 'P_BOLT_LMM' in df_bolt.columns:
        pval_col = 'P_BOLT_LMM'
        print(f"  Using P_BOLT_LMM (non-infinitesimal model)")
    elif 'P_BOLT_LMM_INF' in df_bolt.columns:
        pval_col = 'P_BOLT_LMM_INF'
        print(f"  Using P_BOLT_LMM_INF (infinitesimal model - P_BOLT_LMM not available)")
    else:
        raise ValueError("No p-value column found in BOLT output!")
    
    # Convert to MTAG format
    df_mtag = pd.DataFrame({
        'snpid': df_bolt['SNP'].map(rsid_lookup).fillna(df_bolt['SNP']),  # Use rsID if available, else chr:pos:ref:alt
        'chr': df_bolt['CHR'],
        'bpos': df_bolt['BP'],
        'a1': df_bolt['ALLELE1'],
        'a2': df_bolt['ALLELE0'],
        'freq': df_bolt['A1FREQ'],
        'z': df_bolt['BETA'] / df_bolt['SE'],  # Z-score
        'pval': df_bolt[pval_col],
        'n': sample_size  # Constant for all variants
    })
    
    # Remove rows with missing values
    n_before = len(df_mtag)
    df_mtag = df_mtag.dropna()
    n_after = len(df_mtag)
    
    if n_before > n_after:
        print(f"  Removed {n_before - n_after:,} variants with missing data")
    
    # Count rsID vs coordinate IDs
    n_rsid = df_mtag['snpid'].str.startswith('rs').sum()
    n_coord = len(df_mtag) - n_rsid
    print(f"  Variants with rsID: {n_rsid:,} ({100*n_rsid/len(df_mtag):.1f}%)")
    print(f"  Variants with coordinates: {n_coord:,} ({100*n_coord/len(df_mtag):.1f}%)")
    
    # Write MTAG format file
    df_mtag.to_csv(output_file, sep=' ', index=False, na_rep='NA')
    print(f"  ✓ Created: {output_file}")
    print(f"  ✓ Variants: {len(df_mtag):,}")
    
    return len(df_mtag)

def main():
    # Paths
    srcdir = '/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM'
    ukb21942_d = '/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'
    
    # rsID mapping file
    annot_file = '/net/bmc-lab5/data/kellis/group/tanigawa/data/ukb21942/geno/ukb_genoHM3.annot.genesymbol_mapped.pvar.gz'
    
    # EUR-filtered phenotype file (for sample sizes)
    pheno_file = f'{srcdir}/isolation_run_control.EUR.tsv.gz'
    
    # Output directory
    output_dir = f'{srcdir}/MTAG_Inputs'
    os.makedirs(output_dir, exist_ok=True)
    
    # Phenotypes to process
    phenotypes = ['Loneliness', 'FreqSoc', 'AbilityToConfide']
    
    # Covariate sets to process
    covar_sets = ['Day_NoPCs', 'Day_10PCs']
    
    print("=" * 70)
    print("BOLT-LMM to MTAG Format Conversion")
    print("=" * 70)
    print()
    
    # Load rsID mapping
    rsid_lookup = load_rsid_mapping(annot_file)
    print()
    
    # Get sample sizes for each phenotype
    print("Determining sample sizes from EUR-filtered phenotype file...")
    sample_sizes = {}
    df_pheno = pd.read_csv(pheno_file, sep='\t', compression='gzip')
    for pheno in phenotypes:
        n = df_pheno[pheno].notna().sum()
        sample_sizes[pheno] = n
        print(f"  {pheno}: {n:,} samples")
    print()
    
    # Process each covariate set
    for covar_set in covar_sets:
        print("=" * 70)
        print(f"Processing {covar_set}")
        print("=" * 70)
        
        # Check if result directory exists
        results_dir = f'{srcdir}/results/{covar_set}/EUR'
        if not os.path.exists(results_dir):
            print(f"⚠️  Results directory not found: {results_dir}")
            print(f"   Skipping {covar_set}")
            print()
            continue
        
        # Process each phenotype
        for pheno in phenotypes:
            bolt_file = f'{results_dir}/bolt_{pheno}.{covar_set}.stats.gz'
            
            if not os.path.exists(bolt_file):
                print(f"⚠️  File not found: {bolt_file}")
                print(f"   Skipping {pheno} + {covar_set}")
                continue
            
            # Output file
            output_file = f'{output_dir}/{pheno}.{covar_set}.mtag.sumstats.txt'
            
            # Convert
            try:
                n_variants = convert_bolt_to_mtag(
                    bolt_file=bolt_file,
                    rsid_lookup=rsid_lookup,
                    trait_name=f"{pheno} + {covar_set}",
                    sample_size=sample_sizes[pheno],
                    output_file=output_file
                )
            except Exception as e:
                print(f"❌ Error processing {pheno} + {covar_set}: {e}")
                continue
        
        print()
    
    print("=" * 70)
    print("Conversion Complete!")
    print("=" * 70)
    print()
    print(f"Output directory: {output_dir}")
    print()
    print("Created files:")
    if os.path.exists(output_dir):
        for f in sorted(os.listdir(output_dir)):
            if f.endswith('.mtag.sumstats.txt'):
                filepath = os.path.join(output_dir, f)
                size_mb = os.path.getsize(filepath) / (1024*1024)
                print(f"  {f} ({size_mb:.1f} MB)")
    
    print()
    print("Next steps:")
    print("1. Verify output files in MTAG_Inputs/")
    print("2. Run MTAG on these formatted files")
    print("3. See MTAG documentation: https://github.com/JonJala/mtag")

if __name__ == '__main__':
    main()

