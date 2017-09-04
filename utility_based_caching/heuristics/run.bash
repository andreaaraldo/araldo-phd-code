#!/bin/bash
ITERATIONS=1
EXECUTABLE=approx.o


## This is the other type
ALPHA=1
CTLG=100
SINGLE_STORAGE=1
 #LOAD is Per each client

for SLOWDOWN in 1 ; do
for LOAD in 1 ;  do #in 0.5 1 1.5 2 ;
for SEED in 1 ;  do #`seq 1 20`
for STEPS in  moderate  ; do #triangle moderate
ARGS="$ALPHA $CTLG $LOAD $ITERATIONS $SEED $SLOWDOWN $SINGLE_STORAGE $STEPS"
DIR=~/local_archive/video/heuristic/slowdown-$SLOWDOWN/seed-$SEED/singlestorage-$SINGLE_STORAGE/ctlg-$CTLG/steps-$STEPS
mkdir -p $DIR
echo "running" $ARGS
#nohup ./approx.o $ARGS > $DIR/log-load_$LOAD.log 2>&1 &
./approx.o $ARGS
done
done
done
done
