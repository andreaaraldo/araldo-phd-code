#!/bin/bash
EXECUTABLE=approx.o
ALPHA=1
CTLG=1000
LOAD=2 #Per each client
ITERATIONS=10000

echo ./$EXECUTABLE $ALPHA $CTLG $LOAD $ITERATIONS

./$EXECUTABLE $ALPHA $CTLG $LOAD $ITERATIONS > /tmp/log.log
