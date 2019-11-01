#!/bin/bash -l
#PBS -l mem=32gb
#PBS -l walltime=24:00:00
#PBS -o Output.job
#PBS -j oe
#PBS -l nodes=1:ppn=20
#PBS -M jakub.krajniak@cs.kuleuven.be
#PBS -A lp_polymer_goa_project

module purge

cd $PBS_O_WORKDIR

module load espressopp/adress
module load pyh5md
# Set up OpenMPI environment
n_proc=$(cat $PBS_NODEFILE | wc -l)
n_node=$(cat $PBS_NODEFILE | uniq | wc -l)

RES_STEP="`cat RES`"

date > ${OUTPUT_PREFIX}.log
echo "python -u start_sim.py --conf conf.gro --res_rate $RES_STEP --int_step 1000 --gamma 5.0 --long 40000 --eq 20000 --rng_seed ${SEED} --temperature 298.0 --output_prefix ${OUTPUT_PREFIX} &>> ${OUTPUT_PREFIX}.log" >> ${OUTPUT_PREFIX}.log
python -u start_sim.py --conf conf.gro --res_rate $RES_STEP --temperature 298.0 --int_step 1000 --gamma 5.0 --long 50000 --eq 20000 --rng_seed ${SEED} --output_prefix ${OUTPUT_PREFIX} --top topol.top &>> ${OUTPUT_PREFIX}.log
date >> ${OUTPUT_PREFIX}.log
