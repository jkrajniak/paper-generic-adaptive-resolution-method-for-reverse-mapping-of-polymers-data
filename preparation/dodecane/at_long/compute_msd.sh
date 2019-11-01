#!/bin/bash -l
#PBS -N msd_test_1
#PBS -l mem=32gb
#PBS -l walltime=72:00:00
#PBS -o Output.job
#PBS -j oe
#PBS -l nodes=1:ppn=20
#PBS -M jakub.krajniak@cs.kuleuven.be
#PBS -A lp_polymer_goa_project
#PBS -V

module purge

cd $PBS_O_WORKDIR

module load h5py
module load local_tools

# Set up OpenMPI environment
n_proc=$(cat $PBS_NODEFILE | wc -l)
n_node=$(cat $PBS_NODEFILE | uniq | wc -l)

if [ "X$h5" == "X" ]; then
	for h5 in *.h5; do
	  echo "Computing MSD" >> compute_msd.log
	  echo `basename $h5 .h5` >> compute_msd.log
	  msd.py --chain_length 12 --number_of_chains 500 --max_tau 5000 --output msd_10_`basename ${h5} .h5`.csv --csv --group atoms --nt 20 --with-com no --every-frame 10 $h5 &>> compute_msd.log
	  echo "FINISED `basename $h5 .h5`" >> compute_msd.log
	done
else
	echo "Computing MSD" >> compute_msd.log
	echo `basename $h5 .h5` >> compute_msd.log
	msd.py --chain_length 12 --number_of_chains 500 --max_tau 5000 --output msd_`basename ${h5} .h5`.csv --csv --group atoms --nt 20 --with-com no --every-frame 5 $h5 &>> compute_msd.log
	echo "FINISED `basename $h5 .h5`" >> compute_msd.log
fi
