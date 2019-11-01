#!/bin/bash -l
#PBS -N dod_long0
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

module load espressopp/adress-intel
module load pyh5md
module load h5py/intel-gpfs
# Set up OpenMPI environment
n_proc=$(cat $PBS_NODEFILE | wc -l)
n_node=$(cat $PBS_NODEFILE | uniq | wc -l)
mpdboot -f $PBS_NODEFILE -n $n_node -r ssh -v

mpirun -n 12 python -u start_sim.py --conf conf.gro --top topol.top --thermostat_gamma 5.0 --thermostat lv --run 10000000 --temperature 298.0 --output_prefix sim0 --rng_seed 81256 --skin 0.1 &> sim0.log

mpdallexit
