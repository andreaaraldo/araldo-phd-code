set terminal postscript eps enhanced mono
set output "unsatisfied_ratio.eps"

dat_file = "unsatisfied_ratio.dat"

set ylabel "unsatisfied requests %" 
set xlabel "utility ratio"

plot dat_file \
	using 1:( ($2-$3)*100):( ($2+$3)*100) with filledcu fs transparent pattern 4 ls 4 title "",\
''	using 1:($2*100) with linespoints;
