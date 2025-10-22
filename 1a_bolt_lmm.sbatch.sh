#!/bin/bash
set -beEuo pipefail

# Job submission script for BOLT-LMM

SRCNAME=$(readlink -f "${0}")
SRCDIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/isolation_run_control_BOLT"
REPODIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942"
source "${REPODIR}/helpers/functions.sh"
source_paths "${SRCDIR}"

ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'

analysis_name=$(basename ${SRCDIR} | sed 's/_BOLT$//')

slurm_log_d="$HOME/slurm_logs/${analysis_name}_BOLT"
mkdir -p "${slurm_log_d}"
slurm_job_name=$(basename "${SRCDIR}").bolt

job_list_sh=${slurm_log_d}/${slurm_job_name}.jobs.$(date +%Y%m%d-%H%M%S).sh
batch_size=1 # the number of jobs executed in an array task in SLURM.

# BOLT-LMM requires more resources than PLINK
# Increased memory and threads for BOLT-LMM
# Using kellis partition as requested
# Resources increased for large-scale analysis: 100GB RAM, 100 tasks, 47 hours
sbatch_resources_str='-p kellis --mem=100G -n 100 --nodes=1 --time=47:00:00'
# http://rous.mit.edu/index.php/Luria#User_job_limitations

# log directory
if [ ! -d "${slurm_log_d}" ] ; then mkdir -p "${slurm_log_d}" ; fi

#############################
# constants and loop parameters
#############################

covar_strs=(
    Day_NoPCs
)
keep_sets=(
  EUR
)

# For heritability estimation
covar_strs2=(
    Day_10PCs
)
keep_sets2=(
  EUR
)

# Phenotype columns: Loneliness, FreqSoc, AbilityToConfide
# These are at columns 5,6,9 in the phenotype file
pheno_col_nums='5,6,9'

module load miniconda3/v4
source /home/software/conda/miniconda3/bin/condainit
conda activate /home/mabdel03/data/conda_envs/GWAS_env

#############################
# generate a list of jobs
#############################

job_cmd="bash ${SRCDIR}/bolt_lmm.sh ${analysis_name} BOLT ${pheno_col_nums} 100 100000"

# analysis_name=$1
# out_suffix=$2     # BOLT
# pheno_col_nums=$3 # 5,6,9
# bolt_threads=$4   # 8
# bolt_memory=$5    # 40000
# covar_str=$6      # Day_10PCs or Day_NoPCs
# keep_set=$7       # EUR
# idx=$8            # 1-69

{
    for covar_str in "${covar_strs[@]}" ; do
        for keep in "${keep_sets[@]}" ; do
            for idx in $(seq 1 69) ; do
                echo "${job_cmd} ${covar_str} ${keep} ${idx}"
            done
        done
    done

    # For heritability estimation with PCs
    for covar_str in "${covar_strs2[@]}" ; do
        for keep in "${keep_sets2[@]}" ; do
            for idx in $(seq 1 69) ; do
                echo "${job_cmd} ${covar_str} ${keep} ${idx}"
            done
        done
    done
} > ${job_list_sh}


#############################
# count the number of jobs and tasks (in array job)
#############################
n_jobs=$( cat ${job_list_sh} | wc -l )
n_array_tasks=$(   perl -e "print(int(  (${batch_size} - 1 + ${n_jobs}) / ${batch_size} ))" )

#############################
# helper script for job submission
#############################
parasol_sbatch_sh="${ukb21942_d}/gwas_geno/parasol-sbatch.sh"

echo "## submission of ${n_jobs} jobs in ${n_array_tasks} tasks (each has up to ${batch_size} jobs) ##"
echo "## ${job_list_sh} ##"

(
    # use sub-shell and print the executed command with set -x
    set -x
    sbatch ${sbatch_resources_str} \
        --job-name="${slurm_job_name}" \
        --output="${slurm_log_d}/${slurm_job_name}.%A.%a.out" \
        --error="${slurm_log_d}/${slurm_job_name}.%A.%a.err" \
        --array="1-${n_array_tasks}%5" \
        "${parasol_sbatch_sh}" \
        "${job_list_sh}" \
        "${batch_size}"
)

