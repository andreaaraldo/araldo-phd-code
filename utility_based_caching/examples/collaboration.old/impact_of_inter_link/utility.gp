set terminal postscript eps enhanced mono
set output "utility.eps"

dat_file = "utility.csv"

set ylabel "utility" 
set xlabel "peering link capacity"

plot dat_file \
	using 0:2:xtic(1) with linespoints;
