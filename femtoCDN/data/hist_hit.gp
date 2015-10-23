metric = "hist_cum_hit"
opt = 0.54000; # opt_allocation
opt = 0.46531; # opt_hit_ratio


set terminal postscript eps enhanced color
set output sprintf("%s.eps", metric)
set key outside

set xlabel "Epoch"
set ylabel "Hit ratio"


plot sprintf("%s.dat", metric) \
	using 0:1 title "descent" with lines,\
""	using 0:2 title "dspsa original" with lines,\
""	using 0:3 title "dspsa enhanced" with lines,\
""	using 0:(opt) title "OPT" with lines


