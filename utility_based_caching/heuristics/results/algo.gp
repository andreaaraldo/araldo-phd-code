set linestyle 2 linetype 4
avg_utility = 0.3912;
plot "algo.dat"\
	using 0:1 with lines title "Algorithm",\
""	using 0:(avg_utility) title "Optimum" ls 2 with lines;
