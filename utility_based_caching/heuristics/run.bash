#!/bin/bash
ITERATIONS=100000
EXECUTABLE=approx.o


## This is the other type
ALPHA=1
CTLG=100
SINGLE_STORAGE=10
 #LOAD is Per each client

for SLOWDOWN in 1 10 100 ; do
for LOAD in 0.5 1 1.5 2 ;  do #0.5 1 1.5 2
for SEED in `seq 1 20` ;  do #seq 1 20
for STEPS in triangle moderate; do
ARGS="$ALPHA $CTLG $LOAD $ITERATIONS $SEED $SLOWDOWN $SINGLE_STORAGE $STEPS"
DIR=output/slowdown-$SLOWDOWN/seed-$SEED/singlestorage-$SINGLE_STORAGE/ctlg-$CTLG/steps-$STEPS
mkdir -p $DIR
echo "running" $ARGS
./approx.o $ARGS > $DIR/log-load_$LOAD.log 2>&1 &
done
done
done
done
