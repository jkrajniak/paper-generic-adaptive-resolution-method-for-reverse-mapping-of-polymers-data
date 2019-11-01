#!/bin/bash -l
#PBS -l mem=32gb
#PBS -l walltime=24:00:00
#PBS -o Output.job
#PBS -j oe
#PBS -l nodes=1:ppn=20
#PBS -M jakub.krajniak@cs.kuleuven.be
#PBS -A lp_polymer_goa_project
#PBS -V

module purge

cd $PBS_O_WORKDIR

module load votca/1.4-devel

# Set up OpenMPI environment
n_proc=$(cat $PBS_NODEFILE | wc -l)
n_node=$(cat $PBS_NODEFILE | uniq | wc -l)

echo "Compute bond" > compute_rdf.log
s=0
for h5 in *.h5; do
  cat << EOF | csg_boltzmann --trj $h5 --cg map_aa.xml --top abc.xml
vals ${ref}.bond_vals.$s *:bond:*
vals ${ref}.angle_vals.$s *:angle:*
vals ${ref}.dihedral_vals.$s *:dihedral:*
q
EOF
  let s=$s+1;
done
