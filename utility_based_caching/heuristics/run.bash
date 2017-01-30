#!/bin/bash
EXECUTABLE=approx.o
ALPHA=1
CTLG=100
 #LOAD is Per each client
ITERATIONS=100000


for LOAD in 0.5 1 1.5 2;  do
for SEED in `seq 1 20`;  do
echo ./$EXECUTABLE $ALPHA $CTLG $LOAD $ITERATIONS $SEED
DIR=output/seed-$SEED
mkdir -p $DIR
./$EXECUTABLE $ALPHA $CTLG $LOAD $ITERATIONS $SEED > $DIR/log-load_$LOAD.log &
done
done
