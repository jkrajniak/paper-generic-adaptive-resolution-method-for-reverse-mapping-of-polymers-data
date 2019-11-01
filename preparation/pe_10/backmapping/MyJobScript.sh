#!/bin/bash -l
#PBS -N R_0_100
#PBS -l mem=8gb
#PBS -l walltime=20:00:00
#PBS -o Output.job
#PBS -j oe
#PBS -l nodes=1:ppn=20
#PBS -A lp_polymer_goa_project

module load espressopp/adress_new_current
module load bakery-github-dev

cd $PBS_O_WORKDIR

rng="`shuf -i 12345-99999 -n1`${RNG2}"
OUTPUT_PREFIX=sim0_dev_copy_adress_new_current
LOG="run_${rng}_${OUTPUT_PREFIX}.log"

date > $LOG
module list &>> $LOG
mpirun -np 18 start_backmapping.py @params --output_prefix ${OUTPUT_PREFIX} --rng_seed ${rng} &>> $LOG
date >> $LOG
