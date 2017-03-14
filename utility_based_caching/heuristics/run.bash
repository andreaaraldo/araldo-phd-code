#!/bin/bash
ITERATIONS=100000
EXECUTABLE=approx.o


## This is the other type
ALPHA=1
CTLG=1
SINGLE_STORAGE=0
 #LOAD is Per each client

<<<<<<< HEAD
for SLOWDOWN in 10; do
=======
for SLOWDOWN in 100; do
>>>>>>> 1cfcb02b2744bc5b26c4fe7747e0bfb4d7843b67
for LOAD in 1;  do #0.5 1 1.5 2
for SEED in `seq 1 1`;  do #seq 1 20
echo ./$EXECUTABLE $ALPHA $CTLG $LOAD $ITERATIONS $SEED $SLOWDOWN $SINGLE_STORAGE
DIR=output/slowdown-$SLOWDOWN/seed-$SEED/singlestorage-$SINGLE_STORAGE/ctlg-$CTLG
mkdir -p $DIR
./$EXECUTABLE $ALPHA $CTLG $LOAD $ITERATIONS $SEED $SLOWDOWN $SINGLE_STORAGE > $DIR/log-load_$LOAD.log 
done
done
done
