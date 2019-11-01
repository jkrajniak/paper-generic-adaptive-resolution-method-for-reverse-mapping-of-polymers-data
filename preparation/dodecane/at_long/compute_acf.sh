#!/bin/bash -l
#PBS -N acf_aa
#PBS -l mem=32gb
#PBS -l walltime=72:00:00
#PBS -j oe
#PBS -l nodes=1:ppn=20
#PBS -M jakub.krajniak@cs.kuleuven.be
#PBS -A lp_polymer_goa_project
#PBS -V

module purge

cd $PBS_O_WORKDIR

module load local_tools
module load h5py

# Set up OpenMPI environment
n_proc=$(cat $PBS_NODEFILE | wc -l)
n_node=$(cat $PBS_NODEFILE | uniq | wc -l)

for h5 in *.h5; do
  name="`basename $h5 .h5`"
  echo "Compute ACF: $name" >> compute_acf.log
  acf_vector_analysis.py --trj ${h5} --molecules 500 --N 12 --group atoms --vector 1-12 --end 10000 --prefix ${name} &>> compute_acf.log
done

for h5 in *.h5; do
  name="`basename $h5 .h5`"
  nohup acf_calculation.py --max_tau 5000 --N 75 --csv --dt 0.001 --prefix ${name} ${name}_vector_1_12.dat.npy &>> compute_acf.log &
done

for p in `jobs -p`; do
  wait $p;
done
