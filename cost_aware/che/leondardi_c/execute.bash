#!/bin/bash



rm -f general_tree_extended.o
gcc general_tree_extended.c -lm -o general_tree_extended.o

for POL in "LRU" "pLRU" "CoA"
do
	for PI in 1 2 5 10 100;
	do
		for SEED in {1..20};
		do 
			./general_tree_extended.o $PI $SEED $POL | tail -n1 > /tmp/results-$POL-pi_$PI-seed_$SEED.log
		done
	done
done

exit

rm -f general_tree_original.o
gcc general_tree_original.c -lm -o general_tree_original.o

./general_tree_original.o > /tmp/original_LRU.out

