set terminal postscript eps color
set output "maximum_improvement.eps"

set yrange [0:100]
set ylabel "Maximum improvement (%)"
set xlabel "configuration"

set grid y
set ytics 10

plot "< sort  -k8,8 maximum_improvement.dat" using 0:8 notitle
