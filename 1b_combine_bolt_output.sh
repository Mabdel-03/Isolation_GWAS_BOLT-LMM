#!/bin/bash
set -beEuo pipefail

# Script to combine BOLT-LMM outputs from variant splits

SRCNAME=$(readlink -f "${0}")
SRCDIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942/isolation_run_control_BOLT"
REPODIR="/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942"
ukb21942_d='/home/mabdel03/data/files/Isolation_Genetics/GWAS/Scripts/ukb21942'

source "${REPODIR}/helpers/functions.sh"
source_paths "${SRCDIR}"

slurm_log_d="${SRCDIR}/.slurm_logs"
slurm_job_name=$(basename ${SRCNAME%.sh}).$(basename ${SRCDIR})
job_list_sh=${slurm_log_d}/${slurm_job_name}.jobs.$(date +%Y%m%d-%H%M%S).sh
batch_size=1
sbatch_resources_str='-p kellis --mem=15000 --ntasks=2 --time=1-23:55:00'

# directories
if [ ! -d "${slurm_log_d}" ] ; then mkdir -p "${slurm_log_d}" ; fi

#############################
# constants and loop parameters
#############################

analysis_name=$(basename ${SRCDIR} | sed 's/_BOLT$//')

covar_strs=(
    Day_10PCs
)
keep_sets=(
  EUR
)

# Additional covariate sets
covar_strs2=(
    Day_NoPCs
)
keep_sets2=(
  EUR
)

#############################
# generate a list of jobs
#############################

job_logs="bash ${SRCDIR}/combine_bolt_logs.sh ${analysis_name}"
job_stats="bash ${SRCDIR}/combine_bolt_sumstats.sh ${analysis_name}"

{
    for covar_str in "${covar_strs[@]}" ; do
    for keep_set in "${keep_sets[@]}" ; do
        echo "${job_logs} ${covar_str} ${keep_set}"

        # Loop through each phenotype
        for trait in Loneliness FreqSoc AbilityToConfide ; do
            echo "${job_stats} ${covar_str} ${keep_set} ${trait}"
        done
    done
    done

    for covar_str in "${covar_strs2[@]}" ; do
    for keep_set in "${keep_sets2[@]}" ; do
        echo "${job_logs} ${covar_str} ${keep_set}"

        for trait in Loneliness FreqSoc AbilityToConfide ; do
            echo "${job_stats} ${covar_str} ${keep_set} ${trait}"
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
        --array="1-${n_array_tasks}%3" \
        "${parasol_sbatch_sh}" \
        "${job_list_sh}" \
        "${batch_size}"
)

