#!/bin/bash -l
#PBS -N dod_long_t1_1
#PBS -l mem=32gb
#PBS -l walltime=72:00:00
#PBS -o Output.job
#PBS -j oe
#PBS -l nodes=1:ppn=20
#PBS -M jakub.krajniak@cs.kuleuven.be
#PBS -A lp_polymer_goa_project
#PBS -V

#module load votca/1.2.3

module purge

module load intel
# Set up OpenMPI environment
n_proc=$(cat $PBS_NODEFILE | wc -l)
n_node=$(cat $PBS_NODEFILE | uniq | wc -l)
mpdboot -f $PBS_NODEFILE -n $n_node -r ssh -v

module load espressopp/adress-intel
module load pyh5md
module load h5py/intel-gpfs

cd $PBS_O_WORKDIR

N=1

mpiexec -machinefile $PBS_NODEFILE -n 12  python -u start_sim.py --conf conf.gro --top topol.top --thermostat_gamma 5.0 --thermostat lv --run 10000000 --temperature 298.0 --rng_seed $((23212+$N)) --output_prefix sim${N} --coord init_coord${N} &> sim${N}.log

mpdallexit
