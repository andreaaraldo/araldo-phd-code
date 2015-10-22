set terminal postscript eps enhanced color
set output "algos.eps"
set key outside

set xlabel "Epoch"
set ylabel "Cache fraction allocated \nto the most skewed CP"

set title "Cumulative Steepest Descent with no boost vs. \n DSPSA "

plot "algos.dat" \
	using 0:(0.7) title "OPT" with lines,\
""	using 0:1 title "CSD 1e3 samples" with lines,\
""	using 0:2 title "CSD 1e6 samples" with lines,\
""	using 0:6 title "ZSDSPSA 1e3 samples" with lines,\
""	using 0:5 title "ZSDSPSA 1e6 samples" with lines,\


