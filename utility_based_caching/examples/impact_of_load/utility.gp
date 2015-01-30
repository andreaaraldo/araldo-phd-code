set terminal postscript eps enhanced mono
set output "utility.eps"

dat_file = "utility.dat"

set ylabel "utility" 
set xlabel "load"

plot dat_file \
	using 1:($2-$3):($2+$3) with filledcu fs transparent pattern 4 ls 4 title "",\
''	using 1:2 with linespoints;
