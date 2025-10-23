#!/usr/bin/env python3
"""
Filter phenotype and covariate files to EUR ancestry samples.
More robust than bash/awk approach.
"""

import gzip
import sys

def read_keep_ids(keep_file):
    """Read IIDs from EUR.keep file"""
    eur_ids = set()
    with open(keep_file, 'r') as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 2:
                iid = parts[1]  # Second column is IID
                eur_ids.add(iid)
    return eur_ids

def filter_file(input_file, output_file, eur_ids, ensure_fid_iid_header=False):
    """Filter a gzipped TSV file to EUR samples only"""
    n_in = 0
    n_out = 0
    
    with gzip.open(input_file, 'rt') as fin, gzip.open(output_file, 'wt') as fout:
        # Read header
        header = fin.readline()
        header_parts = header.strip().split('\t')
        
        # BOLT-LMM requires "FID IID" as first two columns
        if ensure_fid_iid_header:
            if header_parts[0] != 'FID' or header_parts[1] != 'IID':
                # Fix header if needed
                print(f"  NOTE: Adjusting header to start with 'FID IID'", file=sys.stderr)
                print(f"    Original: {header_parts[0]} {header_parts[1]}", file=sys.stderr)
                header_parts[0] = 'FID'
                header_parts[1] = 'IID'
                header = '\t'.join(header_parts) + '\n'
        
        fout.write(header)
        
        # Process data rows
        for line in fin:
            n_in += 1
            parts = line.strip().split('\t')
            if len(parts) >= 2:
                iid = parts[1]  # IID is second column
                if iid in eur_ids:
                    fout.write(line)
                    n_out += 1
            
            # Progress indicator
            if n_in % 100000 == 0:
                print(f"  Processed {n_in} samples, kept {n_out}...", file=sys.stderr)
    
    return n_in, n_out

def main():
    # Paths
    ukb21942_d = '/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'
    srcdir = '/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/Isolation_GWAS_BOLT-LMM'
    
    # Use EUR_MM.keep (includes related individuals - appropriate for BOLT-LMM)
    # EUR_MM.keep: ~426K EUR samples (WB_MM + NBW_MM, includes related)
    # EUR.keep: ~353K EUR samples (unrelated only)
    # BOLT-LMM can handle related individuals via GRM, so use EUR_MM for more power
    keep_file = f'{ukb21942_d}/sqc/population.20220316/EUR_MM.keep'
    pheno_in = f'{ukb21942_d}/pheno/isolation_run_control.tsv.gz'
    covar_in = f'{ukb21942_d}/sqc/sqc.20220316.tsv.gz'
    
    pheno_out = f'{srcdir}/isolation_run_control.EUR.tsv.gz'
    covar_out = f'{srcdir}/sqc.EUR.tsv.gz'
    
    print("=" * 60)
    print("Filter to EUR (Including Related Individuals)")
    print("Using EUR_MM.keep for BOLT-LMM Mixed Models")
    print("=" * 60)
    print()
    
    # Read EUR IDs
    print(f"Reading EUR sample IDs from: {keep_file}")
    eur_ids = read_keep_ids(keep_file)
    print(f"  EUR samples to keep: {len(eur_ids)}")
    print()
    
    # Filter phenotype file
    print(f"Filtering phenotype file...")
    print(f"  Input:  {pheno_in}")
    print(f"  Output: {pheno_out}")
    n_pheno_in, n_pheno_out = filter_file(pheno_in, pheno_out, eur_ids, ensure_fid_iid_header=True)
    print(f"  ✓ Complete: {n_pheno_in} input → {n_pheno_out} EUR samples")
    print()
    
    # Filter covariate file (BOLT requires "FID IID" header)
    print(f"Filtering covariate file...")
    print(f"  Input:  {covar_in}")
    print(f"  Output: {covar_out}")
    n_covar_in, n_covar_out = filter_file(covar_in, covar_out, eur_ids, ensure_fid_iid_header=True)
    print(f"  ✓ Complete: {n_covar_in} input → {n_covar_out} EUR samples")
    print()
    
    print("=" * 60)
    print("Filtering Complete!")
    print("=" * 60)
    print()
    print("Summary:")
    print(f"  EUR IDs in keep file:     {len(eur_ids)}")
    print(f"  Phenotype samples (EUR):  {n_pheno_out}")
    print(f"  Covariate samples (EUR):  {n_covar_out}")
    print()
    
    if n_pheno_out != len(eur_ids):
        print(f"  Note: {len(eur_ids) - n_pheno_out} EUR samples missing from phenotype file")
        print("        (normal if some samples have missing data)")
    
    if n_covar_out != len(eur_ids):
        print(f"  Note: {len(eur_ids) - n_covar_out} EUR samples missing from covariate file")
        print("        (normal if some samples have missing data)")
    
    print()
    print("Next: Run BOLT-LMM test")
    print("  sbatch 0c_test_simplified.sbatch.sh")

if __name__ == '__main__':
    main()

