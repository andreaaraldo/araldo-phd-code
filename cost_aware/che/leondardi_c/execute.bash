rm -f general_tree_extended.o
gcc general_tree_extended.c -lm -o general_tree_extended.o

for PI in 10 ;
do
	./general_tree_extended.o $PI 
	# > results_$PI.dat
done
