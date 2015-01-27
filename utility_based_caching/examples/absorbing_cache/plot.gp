set terminal postscript eps enhanced color font "Times-Roman" 32
set output "results.eps"

set size 2,1;
set yrange [0.97:0.99];

set xtic rotate by -45 scale 0
set xlabel "requests"
set ylabel "average QoE"
set key top outside

plot "results.dat" \
	using 1:2 title "without cache" with linespoints,\
  ''using 1:3 title "with cache" with linespoints
;
