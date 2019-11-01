#!/bin/bash -l
#PBS -N dod_long_npt3
#PBS -l mem=32gb
#PBS -l walltime=48:00:00
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

N=3

mpirun -n 12 python -u start_sim.py --conf conf.gro --top topol.top --thermostat_gamma 5.0 --thermostat lv --run 5000000 --temperature 298.0 --output_prefix sim${N} --pressure 1.0 --barostat br --rng_seed 8122${N} --skin 0.1 &> sim${N}.log

mpdallexit
