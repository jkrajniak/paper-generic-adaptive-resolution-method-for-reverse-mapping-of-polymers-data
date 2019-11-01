#!/bin/bash 
#PBS -N PE_CG_423
#PBS -l mem=16gb
#PBS -l walltime=24:00:00
#PBS -o Output.job
#PBS -j oe
#PBS -l nodes=1:ppn=20
#PBS -M jakub.krajniak@kuleuven.be
#PBS -V

module purge
module load votca/1.3-devel-github-foss
module remove OpenMPI
module load GROMACS/5.0.4-intel-2014a-hybrid

cd $PBS_O_WORKDIR

# Set up OpenMPI environment
n_proc=$(cat $PBS_NODEFILE | wc -l)
n_node=$(cat $PBS_NODEFILE | uniq | wc -l)
mpdboot -f $PBS_NODEFILE -n $n_node -r ssh -v

rm done

csg_inverse --options settings.xml

mpdallexit
