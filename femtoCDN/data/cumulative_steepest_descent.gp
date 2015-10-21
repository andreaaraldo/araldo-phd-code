set terminal postscript eps enhanced mono
set output "cumulative_steepest_descent.eps"


set multiplot layout 2,1
set xlabel "Epoch"
set ylabel "Cache fraction allocated \nto the most skewed CP"
set yrange[0:1]

set title "Performance without boost"

plot "cumulative_steepest_descent.dat" \
	using 0:(0.7) title "OPT" with lines,\
""	using 0:1 title "1e3 samples and no boost" with lines,\
""	using 0:2 title "1e6 samples and no boost" with lines


set title "Performance with boost and 1e6 samples"

plot "cumulative_steepest_descent.dat" \
	using 0:4 notitle with lines,\

