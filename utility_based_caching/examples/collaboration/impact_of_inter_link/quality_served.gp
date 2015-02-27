set terminal postscript eps enhanced mono
set output "quality_served.eps"


set multiplot layout 3, 1 title "Cached quality"

set yrange[-0.1:2.5]

dat_file = "quality_served.csv"

set ylabel "quality served " 
set xlabel "rank"
set logscale x;

plot dat_file \
	using 1:2 with lines title "no peering";


plot dat_file \
	using 1:($3+0) with lines title "peering at 490 Kbps";



plot dat_file \
	using 1:($4+0) with lines title "peering at 1 Gbps" ;

# pointtype 6

