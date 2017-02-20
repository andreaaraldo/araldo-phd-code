#!/bin/bash
export  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/ibm/ILOG/CPLEX_Studio1261/opl/bin/x86-64_linux

cp ../../model.mod /tmp/model.mod
sed -i 's/CUSTOMTYPE/int/g' /tmp/model.mod
sed -i 's/CACHETYPE/boolean/g' /tmp/model.mod

oplrun /tmp/model.mod toy_case_2.dat
