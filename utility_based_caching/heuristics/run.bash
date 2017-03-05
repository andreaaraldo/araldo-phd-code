#!/bin/bash
ITERATIONS=100
EXECUTABLE=approx.o


## This is the other type
ALPHA=1
CTLG=100
 #LOAD is Per each client

for SLOWDOWN in 1 10 100; do
for LOAD in 0.5 1 1.5 2;  do #0.5 1 1.5 2
for SEED in `seq 1 1`;  do #seq 1 20
echo ./$EXECUTABLE $ALPHA $CTLG $LOAD $ITERATIONS $SEED $SLOWDOWN
DIR=output/slowdown-$SLOWDOWN/seed-$SEED
mkdir -p $DIR
./$EXECUTABLE $ALPHA $CTLG $LOAD $ITERATIONS $SEED $SLOWDOWN > $DIR/log-load_$LOAD.log &
done
done
done
