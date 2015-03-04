#!/bin/bash



rm -f general_tree_extended.o
gcc general_tree_extended.c -lm -o general_tree_extended.o

for PI in 1 2 5 10 100 ;
do
	for SEED in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ;
	do 
		./general_tree_extended.o $PI $SEED > results/results-CoA-pi_$PI-seed_$SEED.log
	done
done

exit

rm -f general_tree_original.o
gcc general_tree_original.c -lm -o general_tree_original.o

./general_tree_original.o > /tmp/original_LRU.out

