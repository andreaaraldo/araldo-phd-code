rm -f general_tree_extended.o
gcc general_tree_extended.c -lm -o general_tree_extended.o

PI=10
SEED=1
./general_tree_extended.o $PI $SEED > results/results-pi_$PI-seed_$SEED.log

exit
for PI in 1 2 5 10 ;
do
	for SEED in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ;
		do 
			./general_tree_extended.o $PI $SEED > results/results-pi_$PI-seed_$SEED.log
		done
done
