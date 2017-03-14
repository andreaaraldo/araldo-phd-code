#!/bin/bash
ITERATIONS=1000
EXECUTABLE=approx.o


## This is the other type
ALPHA=1
CTLG=1
SINGLE_STORAGE=0
 #LOAD is Per each client

for SLOWDOWN in 1 10 100; do
for LOAD in 1;  do #0.5 1 1.5 2
for SEED in `seq 1 1`;  do #seq 1 20
for STEPS in triangle moderate; do
COMMAND= ./$EXECUTABLE $ALPHA $CTLG $LOAD $ITERATIONS $SEED $SLOWDOWN $SINGLE_STORAGE $STEPS
DIR=output/slowdown-$SLOWDOWN/seed-$SEED/singlestorage-$SINGLE_STORAGE/ctlg-$CTLG/steps-$STEPS
mkdir -p $DIR
echo $COMMAND
$COMMAND > $DIR/log-load_$LOAD.log &
done
done
done
done
