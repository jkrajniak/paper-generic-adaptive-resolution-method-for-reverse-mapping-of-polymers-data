#!/bin/bash -l
#PBS -N msd_aa_t1_dod
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

echo "Compute RDF" > compute_rdf.log
s=0
for h5 in *.h5; do
  echo $h5 >> compute_rdf.log
  csg_stat --top abc.xml --trj $h5 --options settings_aa.xml --ext sim${s} --cg map_aa.xml --nt 20 &>> compute_rdf.log
  let s=$s+1;
  #csg_stat --top topol.xml --options settings_aa.xml --ext $s --trj ${s}but.h5 --cg map_aa.xml --nt $n_proc &>> compute_rdf.log
done
