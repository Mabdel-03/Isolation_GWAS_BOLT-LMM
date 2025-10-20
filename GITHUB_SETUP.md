# GitHub Setup Instructions

## Repository is Ready!

Your local Git repository has been initialized and committed. Now you need to create the GitHub repository and push your code.

## Step 1: Create GitHub Repository

1. Go to [GitHub](https://github.com)
2. Click the **+** icon in the top right
3. Select **New repository**
4. Fill in the details:
   - **Repository name**: `BOLT-LMM-isolation-GWAS` (or your preferred name)
   - **Description**: `BOLT-LMM GWAS pipeline for binary isolation phenotypes (Day et al. 2018 methodology)`
   - **Visibility**: Choose **Public** or **Private**
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
5. Click **Create repository**

## Step 2: Connect and Push to GitHub

GitHub will show you commands. Use these:

```bash
# Navigate to your repository
cd /Users/mahmoudabdelmoneum/Desktop/MIT/UROPS/TsaiKellis_Reorganized/UKBB/GWAS/BOLT-LMM/Run_1/ukb21942/isolation_run_control_BOLT

# Rename branch to main (optional, recommended)
git branch -M main

# Add GitHub as remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/BOLT-LMM-isolation-GWAS.git

# Push to GitHub
git push -u origin main
```

## Alternative: Using SSH

If you prefer SSH (recommended for frequent pushes):

```bash
# Add remote with SSH
git remote add origin git@github.com:YOUR_USERNAME/BOLT-LMM-isolation-GWAS.git

# Push
git push -u origin main
```

## Step 3: Verify Upload

1. Go to your GitHub repository URL
2. Verify all files are there
3. Check that README.md displays properly
4. Verify START_HERE.md appears in the file list

## What's Included

Your repository contains:
- ✅ 9 executable scripts (.sh files)
- ✅ 6 documentation files (.md files)
- ✅ .gitignore (prevents committing data files)
- ✅ LICENSE (MIT License)
- ✅ No data files (properly excluded)

## Repository Structure on GitHub

```
BOLT-LMM-isolation-GWAS/
├── START_HERE.md           ← GitHub will show this prominently
├── README.md               ← Main documentation
├── LICENSE
├── .gitignore
│
├── Core Scripts/
│   ├── bolt_lmm.sh
│   ├── 1a_bolt_lmm.sbatch.sh
│   ├── 1b_combine_bolt_output.sh
│   ├── combine_bolt_logs.sh
│   ├── combine_bolt_sumstats.sh
│   └── paths.sh
│
├── Setup Scripts/
│   ├── 0_convert_to_bed.sh
│   └── 0_prepare_model_snps.sh
│
├── Utility/
│   └── 99_check_progress.sh
│
└── Documentation/
    ├── START_HERE.md
    ├── BINARY_TRAITS_INFO.md
    ├── README.md
    ├── QUICK_START.md
    ├── SETUP_CHECKLIST.md
    └── FILE_MANIFEST.md
```

## Recommended GitHub Repository Settings

### About Section
- **Description**: BOLT-LMM GWAS pipeline for binary isolation phenotypes following Day et al. 2018
- **Website**: (optional) Link to your lab/project page
- **Topics**: `gwas`, `bolt-lmm`, `ukbiobank`, `genetics`, `isolation`, `binary-traits`, `mixed-models`

### README
Your README.md will automatically display. It includes:
- Project overview
- Phenotype descriptions
- Workflow instructions
- Key differences from PLINK
- References

## Making Your Repository More Discoverable

Add these topics (GitHub Settings → About → Topics):
- `gwas`
- `bolt-lmm`
- `genomics`
- `uk-biobank`
- `binary-traits`
- `mixed-models`
- `association-testing`
- `population-genetics`

## Future Updates

To update your repository after making changes:

```bash
cd /Users/mahmoudabdelmoneum/Desktop/MIT/UROPS/TsaiKellis_Reorganized/UKBB/GWAS/BOLT-LMM/Run_1/ukb21942/isolation_run_control_BOLT

# Check what changed
git status

# Add changes
git add -A

# Commit with message
git commit -m "Description of changes"

# Push to GitHub
git push
```

## Collaborating

If others want to use your pipeline:

```bash
# They can clone it
git clone https://github.com/YOUR_USERNAME/BOLT-LMM-isolation-GWAS.git

# Or download as ZIP from GitHub
```

## Troubleshooting

### Authentication Issues

If you get authentication errors:

1. **HTTPS**: Generate a Personal Access Token (PAT)
   - GitHub Settings → Developer settings → Personal access tokens
   - Use PAT as password when pushing

2. **SSH**: Set up SSH key
   ```bash
   # Generate key
   ssh-keygen -t ed25519 -C "your_email@example.com"
   
   # Add to GitHub
   # GitHub Settings → SSH and GPG keys → New SSH key
   ```

### Remote Already Exists

If you get "remote origin already exists":
```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/BOLT-LMM-isolation-GWAS.git
```

## Privacy Considerations

✅ **Safe to share publicly**:
- All scripts (no credentials)
- Documentation
- Configuration templates

❌ **DO NOT commit** (already in .gitignore):
- Data files (phenotypes, genotypes)
- Results (summary statistics)
- SLURM logs
- Any files with participant data

## Citing Your Repository

If others use your code, they can cite it as:

```
Abdelmoneum, M. (2025). BOLT-LMM GWAS Pipeline for Isolation Phenotypes. 
GitHub repository: https://github.com/YOUR_USERNAME/BOLT-LMM-isolation-GWAS
```

## Example Repository Description

Copy this for your GitHub repository description:

```
🧬 BOLT-LMM GWAS Pipeline for Binary Isolation Phenotypes

Complete analysis pipeline for running genome-wide association studies on 
binary isolation-related phenotypes (Loneliness, Social Contact Frequency, 
Ability to Confide) using BOLT-LMM mixed models.

Based on the methodology from Day et al. (2018) "Elucidating the genetic 
basis of social interaction and isolation" Nature Communications.

Features:
- Liability threshold model for binary traits
- Proper handling of population structure via GRM
- Comprehensive documentation
- HPC-ready SLURM scripts
- Quality control tools

Topics: #GWAS #BOLT-LMM #UKBiobank #BinaryTraits #MixedModels #Genetics
```

## Questions?

- **GitHub Issues**: Enable Issues in repository settings for questions
- **Documentation**: All usage info is in the .md files
- **Updates**: Star/Watch the repository to track changes

---

**Ready?** → Create your GitHub repository and push! 🚀

