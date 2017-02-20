#!/bin/bash
ITERATIONS=1000000
EXECUTABLE=approx.o

DATFILE='toy_cases/toy_case_2.dat'
grep "ObjRequests" $DATFILE > /tmp/req.dat
./$EXECUTABLE /tmp/req.dat $ITERATIONS



exit

## This is the other type
ALPHA=1
CTLG=100
 #LOAD is Per each client

for LOAD in 0.5 1 1.5 2;  do
for SEED in `seq 1 20`;  do
echo ./$EXECUTABLE $ALPHA $CTLG $LOAD $ITERATIONS $SEED
DIR=output/seed-$SEED
mkdir -p $DIR
./$EXECUTABLE $ALPHA $CTLG $LOAD $ITERATIONS $SEED > $DIR/log-load_$LOAD.log &
done
done
