set terminal postscript eps enhanced color
set output "quality_served.eps"

set yrange[-0.1:2.5]

dat_file = "quality_served.dat"

set ylabel "quality served " 
set xlabel "rank"
set logscale x;

plot dat_file \
	using 1:6 with lines title "uratio=1.5",\
''	using 1:8 with lines title "uratio=2",\
''	using 1:12 with lines title "uratio=4";


#''	using 1:6:7 with errorbars linecolor 1 pointsize 0 notitle;

