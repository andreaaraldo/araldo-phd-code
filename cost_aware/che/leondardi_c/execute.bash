#!/bin/bash



rm -f general_tree_extended.o
gcc general_tree_extended.c -lm -o general_tree_extended.o

#POL can be "LRU" "pLRU" "CoA"

for POL in "CoA"
do
	for PI in 10;
	do
		for ALPHA in 0.8 0.85 0.9 0.95 1 1.05 1.1 1.15 1.2;
		do
			for SEED in {1..20};
			do 
				./general_tree_extended.o $PI $SEED $POL $ALPHA| tail -n1 > /tmp/che_alpha/results-$POL-pi_$PI-alpha_$ALPHA-seed_$SEED.log
			done
		done
	done
done

exit

rm -f general_tree_original.o
gcc general_tree_original.c -lm -o general_tree_original.o

./general_tree_original.o > /tmp/original_LRU.out

