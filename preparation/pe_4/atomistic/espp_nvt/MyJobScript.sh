#!/bin/bash -l
#PBS -N PE_423_AT_espp
#PBS -l walltime=24:00:00
#PBS -o Output.job
#PBS -j oe
#PBS -l nodes=1:ppn=20
#PBS -M jakub.krajniak@cs.kuleuven.be


module purge
module load espressopp/adress-intel-devel
module load bakery

cd $PBS_O_WORKDIR

# Set up OpenMPI environment
n_proc=$(cat $PBS_NODEFILE | wc -l)
n_node=$(cat $PBS_NODEFILE | uniq | wc -l)
mpdboot -f $PBS_NODEFILE -n $n_node -r ssh -v

mpirun -n 18 start_simulation.py @params &>> sim.log

mpdallexit
