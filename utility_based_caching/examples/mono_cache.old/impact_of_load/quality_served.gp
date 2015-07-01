set terminal postscript eps enhanced color
set output "quality_served.eps"

set yrange[-0.1:2.5]

dat_file = "quality_served.dat"

set ylabel "quality served " 
set xlabel "rank"
set logscale x;

plot dat_file \
	using 1:2 with lines title "load=[0.42, 2.8, 5]",\
''	using 1:6 with lines title "load=[1.7, 11, 20]",\
''	using 1:10 with lines title "load=[3.4, 22, 40]",\
''	using 1:12 with lines title "load=[6.8, 44, 80]";



#''	using 1:6:7 with errorbars linecolor 1 pointsize 0 notitle;

