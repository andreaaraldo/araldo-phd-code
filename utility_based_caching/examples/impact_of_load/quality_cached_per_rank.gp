set terminal postscript eps enhanced color
set output "quality_cached_per_rank.eps"

set yrange[-0.1:2.5]

dat_file = "quality_cached_per_rank.dat"

set ylabel "quality cached " 
set xlabel "rank"
set logscale x;

plot dat_file \
	using 1:2 with lines title "load=0.25",\
''	using 1:6 with lines title "load=1",\
''	using 1:10 with lines title "load=2",\
''	using 1:12 with lines title "load=4";


#''	using 1:6:7 with errorbars linecolor 1 pointsize 0 notitle;

