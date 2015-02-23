set terminal postscript eps enhanced mono
set output "unsatisfied_ratio.eps"

dat_file = "unsatisfied_ratio.dat"

set ylabel "unsatisfied requests %" 
set xlabel "load"

set xtics ("[0.43, 2.8, 5.0]" 0.25, "[0.85, 5.5, 10]" 0.50, "[1.7, 11, 20]" 1, "[2.6, 17, 30]" 1.5, "[3.4, 22, 40]" 2, "[6.8, 44, 80]" 4, "[14, 88, 160]" 8) rotate by -90



plot dat_file \
	using 1:( ($2-$3)*100):( ($2+$3)*100) with filledcu fs transparent pattern 4 ls 4 notitle,\
''	using 1:($2*100) with linespoints notitle;
