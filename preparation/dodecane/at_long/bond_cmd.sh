#!/bin/bash
s=0
for h5 in *.h5; do
  cat << EOF | csg_boltzmann --trj $h5 --cg map_aa.xml --top abc.xml --first-frame 5000
vals ${1}.bond_vals.$s *:bond:*
vals ${1}.angle_vals.$s *:angle:*
vals ${1}.dihedral_vals.$s *:dihedral:*
q
EOF
  let s=$s+1;
done
