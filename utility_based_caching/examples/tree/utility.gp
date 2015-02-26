set terminal postscript eps enhanced mono
set output "utility.eps"

set yrange [:2.02]

set ylabel "average utility" 
set xlabel "load"
set grid


plot '<sort -k1 utility.dat' \
	using 1:2 with linespoints notitle;
