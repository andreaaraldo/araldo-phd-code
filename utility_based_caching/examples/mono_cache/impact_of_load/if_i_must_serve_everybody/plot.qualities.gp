set terminal postscript eps enhanced color font "Times-Roman" 32
set output "results.qualities.eps"
set title "Impact of load (serving everybody)"

set size 2,1;
set yrange [-0.1:2.1]

set xtic rotate by -45 scale 0
set xlabel "object rank"
set logscale x;
set ylabel "cached quality"
set key top outside;
set key autotitle columnhead;
set pointsize 3;

plot 'results.qualities.csv' \
	using 1:2 with lines,\
''	using 1:4 with lines,\
''	using 1:5 with lines,\
''	using 1:6 with lines\

;
