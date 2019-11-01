#!/bin/bash -l
#PBS -N DOD_NPT_1
#PBS -l walltime=24:00:00
#PBS -o Output.job
#PBS -j oe
#PBS -l nodes=2:ppn=24
#PBS -M jakub.krajniak@cs.kuleuven.be

#module load votca/1.2.3

module purge
module load GROMACS/5.0.4-intel-2014a-hybrid
MDRUN="mdrun_mpi -v" 

cd $PBS_O_WORKDIR

# Set up OpenMPI environment
n_proc=$(cat $PBS_NODEFILE | wc -l)
n_node=$(cat $PBS_NODEFILE | uniq | wc -l)
mpdboot -f $PBS_NODEFILE -n $n_node -r ssh -v

mpiexec -np $n_proc $MDRUN -cpi state.cpt

mpdallexit
