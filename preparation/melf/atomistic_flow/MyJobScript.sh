#!/bin/bash -le
#PBS -N MELF_NPT_468
#PBS -l walltime=48:00:00
#PBS -o Output.job
#PBS -j oe
#PBS -l nodes=1:ppn=20
#PBS -M jakub.krajniak@cs.kuleuven.be
#PBS -A  lp_polymer_goa_project


module purge
module load GROMACS

MDRUN="mdrun_mpi -cpi state.cpt -v"
GROMPP="grompp_mpi"

cd $PBS_O_WORKDIR

# Set up OpenMPI environment
n_proc=$(cat $PBS_NODEFILE | wc -l)
n_node=$(cat $PBS_NODEFILE | uniq | wc -l)
mpdboot -f $PBS_NODEFILE -n $n_node -r ssh -v

LOG="${PBS_O_WORKDIR}/${PBS_JOBID}.log"

function logg() {
    echo ">>>>>> $1" &>> $LOG
}

FIRST_STEP=1
LAST_DIR=""

EQ_FILES="em.mdp nvt_800.mdp nvt_298.mdp npt.mdp npt_298.mdp"
ROOT_FILES="topol.top"

for eq in $EQ_FILES; do
    logg "Start $eq"
    NEW_DIR="`basename $eq .mdp`"
    if [ -d $NEW_DIR ]; then
        if [ -f "${NEW_DIR}/done" ]; then
            logg "Step $eq exists and it's done"
            LAST_DIR=$NEW_DIR
            FIRST_STEP=0
            continue
        else
            rm -rvf $NEW_DIR &>> $LOG
            mkdir $NEW_DIR
        fi
    else
        mkdir $NEW_DIR
    fi

    if [ "$FIRST_STEP" = "1" ]; then
        cp -v conf.gro $NEW_DIR/ &>> $LOG
    else
        cp -v ${LAST_DIR}/confout.gro $NEW_DIR/conf.gro &>> $LOG
    fi
    cp -v $eq $NEW_DIR/ &>> $LOG

    cd $NEW_DIR
    for rf in $ROOT_FILES; do
        ln -s ../$rf . &>> $LOG
    done
    $GROMPP -f $eq
    [ "$?" != "0" ] && exit $?
    mpirun -n $n_proc $MDRUN
    [ "$?" != "0" ] && exit $?
    LAST_DIR=$NEW_DIR
    FIRST_STEP=0
    touch "done"
    cd ..
done
