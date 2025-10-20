# Path configuration for isolation_run_control_BOLT analysis

ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'
tmp_ukb21942_d='/tmp/kellis/ukb21942'

# BOLT-LMM specific paths
# Update these paths based on your BOLT-LMM installation
BOLT_LMM_DIR="/path/to/BOLT-LMM_v2.4.1"
BOLT_TABLES_DIR="${BOLT_LMM_DIR}/tables"

# LD scores for BOLT-LMM calibration (choose appropriate reference)
# For European ancestry:
LD_SCORES_FILE="${BOLT_TABLES_DIR}/LDSCORE.1000G_EUR.tab.gz"

# Genetic map for interpolation
GENETIC_MAP_FILE="${BOLT_TABLES_DIR}/genetic_map_hg19_withX.txt.gz"

# Model SNPs for genetic relationship matrix
MODEL_SNPS_FILE="${ukb21942_d}/geno/ukb_genoHM3/ukb_genoHM3_modelSNPs.txt"

