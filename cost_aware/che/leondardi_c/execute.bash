#!/bin/bash
rm -f general_tree_extended.o
gcc general_tree_extended.c -lm -o general_tree_extended.o


for PI in 10000 ;
do
	for SEED in 1 2 3 ;
	do 
		./general_tree_extended.o $PI $SEED > results/results-pi_$PI-seed_$SEED.log
	done
done
