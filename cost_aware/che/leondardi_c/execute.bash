#!/bin/bash



rm -f general_tree_extended.o
gcc general_tree_extended.c -lm -o general_tree_extended.o

for POL in "LRU" "pLRU" "CoA"
do
	for PI in 10;
	do
		for ALPHA in 0.8 0.9 1 1.1 1.2;
		do
			for SPLIT in "0.25_0.25_0.5" "0.333_0.333_0.334" "0.5_0.25_0.25"
			do
				for SEED in {1..20};
				do 
					./general_tree_extended.o $PI $SEED $POL $ALPHA $SPLIT | tail -n1 > /tmp/che_alpha/results-$POL-pi_$PI-alpha_$ALPHA-split_$SPLIT-seed_$SEED.log
				done
			done
		done
	done
done

exit

rm -f general_tree_original.o
gcc general_tree_original.c -lm -o general_tree_original.o

./general_tree_original.o > /tmp/original_LRU.out

