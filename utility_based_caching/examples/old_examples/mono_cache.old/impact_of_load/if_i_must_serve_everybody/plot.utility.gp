set terminal postscript eps enhanced color font "Times-Roman" 32
set output "results.utility.eps"
set title "Impact of load (serving everybody)"

set size 2,1;
set xrange [0:2.5]

set xtic rotate by -45 scale 0
set xlabel "load"
set ylabel "average utility"
set key top outside;

plot 'results.utility.csv' \
	using 1:2 with linespoints\

;
