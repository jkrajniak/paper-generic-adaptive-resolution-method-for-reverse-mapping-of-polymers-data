#!/bin/bash 
#PBS -N DOD_CG_big
#PBS -l mem=16gb
#PBS -l walltime=48:00:00
#PBS -o Output.job
#PBS -j oe
#PBS -l nodes=1:ppn=24:haswell
#PBS -M jakub.krajniak@kuleuven.be
#PBS -V

module purge
module load votca/1.3_dev-foss2
module load GROMACS/5.0.4-intel-2014a-hybrid

cd $PBS_O_WORKDIR

# Set up OpenMPI environment
n_proc=$(cat $PBS_NODEFILE | wc -l)
n_node=$(cat $PBS_NODEFILE | uniq | wc -l)
mpdboot -f $PBS_NODEFILE -n $n_node -r ssh -v

rm done

csg_inverse --options settings.xml

mpdallexit
