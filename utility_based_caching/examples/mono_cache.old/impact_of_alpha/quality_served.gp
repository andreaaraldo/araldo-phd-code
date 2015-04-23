set terminal postscript eps enhanced color
set output "quality_served.eps"

set yrange[-0.1:2.5]

dat_file = "quality_served.dat"

set ylabel "quality served " 
set xlabel "rank"
set logscale x;

plot dat_file \
	using 1:2 with lines title "alpha=0",\
''	using 1:6 with lines title "alpha=0.8",\
''	using 1:8 with lines title "alpha=1",\
''	using 1:10 with lines title "alpha=1.2";


#''	using 1:6:7 with errorbars linecolor 1 pointsize 0 notitle;

