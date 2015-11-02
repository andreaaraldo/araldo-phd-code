set terminal postscript eps color
set output "maximum_improvement.eps"

set key left

set multiplot layout 1,2

set ylabel "Hit ratio (%)"
set xlabel "configuration"

set grid y

set title "With cache size 1e1, 1e2, 1e3"

plot \
 "< sort  -k12,12 maximum_improvement.dat" using 0:($12) with lines title "opt"
#, \
# "" using 0:($11*100) with lines title "unif" 

#set title "With cache size 1e2, 1e3"

#plot \
# "< sort  -k10,10 maximum_improvement.dat  | awk '{if ($5!=1e+01) print $0; }' " using 0:($10*100) with lines title "opt", \
# "" using 0:($11*100) with lines title "unif"
