set terminal postscript eps enhanced color font "Times-Roman" 32
set output "results.eps"
set title "Impact of alpha"

set size 2,1;
set yrange [-0.1:2.1]

set xtic rotate by -45 scale 0
set xlabel "object rank"
set logscale x;
set ylabel "cached quality"
set key top outside;

plot 'cached_qualities.csv' \
	using 1:2 title "alpha=0.5" with linespoints,\
''	using 1:3 title "alpha=0.8" with linespoints,\
''	using 1:4 title "alpha=1" with linespoints,\
''	using 1:5 title "alpha=1.2" with linespoints,\
''	using 1:7 title "alpha=2" with linespoints,\
''	using 1:8 title "alpha=3" with linespoints\

;
