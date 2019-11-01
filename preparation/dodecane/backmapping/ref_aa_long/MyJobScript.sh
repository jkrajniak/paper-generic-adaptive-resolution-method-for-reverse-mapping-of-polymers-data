#!/bin/bash -l
#PBS -N dod_lng_aa
#PBS -l mem=32gb
#PBS -l walltime=168:00:00
#PBS -o Output.job
#PBS -j oe
#PBS -l nodes=1:ppn=20
#PBS -M jakub.krajniak@cs.kuleuven.be
#PBS -A lp_polymer_goa_project
#PBS -V

#module load votca/1.2.3

module purge

cd $PBS_O_WORKDIR

module load espressopp/adress
module load pyh5md
# Set up OpenMPI environment
n_proc=$(cat $PBS_NODEFILE | wc -l)
n_node=$(cat $PBS_NODEFILE | uniq | wc -l)
mpdboot -f $PBS_NODEFILE -n $n_node -r ssh -v

mpirun -n $n_proc python -u start_sim.py --conf conf.gro --top topol.top --gamma 5.0 --thermostat lv --eq 10000000 --temperature 298.0 &> sim.log

mpdallexit
