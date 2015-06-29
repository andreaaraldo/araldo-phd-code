#!/bin/bash
export  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/ibm/ILOG/CPLEX_Studio1261/opl/bin/x86-64_linux
octave --quiet scenario_script.m 
