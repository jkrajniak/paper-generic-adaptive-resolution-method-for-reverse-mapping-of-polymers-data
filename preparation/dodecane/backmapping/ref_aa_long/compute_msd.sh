#!/bin/bash -l
#PBS -N msd_aa_ref_dod
#PBS -l mem=32gb
#PBS -l walltime=48:00:00
#PBS -o Output.job
#PBS -j oe
#PBS -l nodes=1:ppn=24
#PBS -M jakub.krajniak@cs.kuleuven.be
#PBS -A lp_polymer_goa_project
#PBS -V

module purge

cd $PBS_O_WORKDIR

module load h5py/2.2.1-foss-2014a-Python-2.7.6
module load local_tools

# Set up OpenMPI environment
n_proc=$(cat $PBS_NODEFILE | wc -l)
n_node=$(cat $PBS_NODEFILE | uniq | wc -l)

#echo "Computing MSD internal distance"  &>> compute_msd.log
echo "Computing MSD" &> compute_msd.log
for s in sim0 sim1 sim2 sim3; do
    msd.py --chain_length 12 --number_of_chains 500 --max_tau 5000 --group atoms --output ref_msd_${s}but --end 10000 --csv --nt 24 --with-com no --every-frame 5 ${s}but.h5  &>> compute_msd.log
done
