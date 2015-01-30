set terminal postscript eps enhanced color
set output "quality_cached_per_rank.eps"
dat_file = "quality_cached_per_rank.dat"

set yrange[-0.1:2.5]


set ylabel "quality cached" 
set xlabel "rank"
set logscale x;

plot dat_file \
	using 1:6 with lines title "uratio=1.5",\
''	using 1:8 with lines title "uratio=2",\
''	using 1:12 with lines title "uratio=4";


#''	using 1:6:7 with errorbars linecolor 1 pointsize 0 notitle;

