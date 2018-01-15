#!/bin/bash
ITERATIONS=1


## This is the other type
ALPHA=1
CTLG=100
SINGLE_STORAGE=1
TOPOLOGY="1server"
 #LOAD is Per each client

for SLOWDOWN in 1 ; do
for LOAD in 1 ;  do #in 0.5 1 1.5 2 ;
for SEED in 2 ;  do #`seq 1 20`
for STEPS in  moderate  ; do #triangle moderate
ARGS="$ALPHA $CTLG $LOAD $ITERATIONS $SEED $SLOWDOWN $SINGLE_STORAGE $STEPS $TOPOLOGY"
DIR=~/local_archive/video/heuristic/slowdown-$SLOWDOWN/seed-$SEED/singlestorage-$SINGLE_STORAGE/ctlg-$CTLG/steps-$STEPS
mkdir -p $DIR
echo "running" $ARGS
#nohup ./approx.o $ARGS > $DIR/log-load_$LOAD.log 2>&1 &
gdb --args ./approx.o $ARGS
done
done
done
done
