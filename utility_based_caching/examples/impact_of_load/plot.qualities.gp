set terminal postscript eps enhanced color font "Times-Roman" 32
set output "results.qualities.eps"

set size 2,1;

set xtic rotate by -45 scale 0
set xlabel "object rank"
set logscale x;
set ylabel "cached quality"
set key top outside;
set key autotitle columnhead;

plot 'results.qualities.csv' \
	using 1:2 with linespoints,\
''	using 1:3 with linespoints,\
''	using 1:4 with linespoints,\
''	using 1:5 with linespoints,\
''	using 1:6 with linespoints,\
''	using 1:7 with linespoints\

;
