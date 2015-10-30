set terminal postscript eps color
set output "doubling_the_cache.eps"

set multiplot layout 1,3 title "Gain achieved doubling the cache size"

set logscale x
set xlabel "catalog size"
set ylabel "gain%"

set title "c2ctlg 1e-4"

plot "< cat doubling_the_cache.dat | awk '{if ($3==0.0001 && $2==0) print $0} '" using 1:4 with lines title "alpha 0" ,\
"< cat doubling_the_cache.dat | awk '{if ($3==0.0001 && $2==0.5) print $0} '" using 1:4 with lines title "alpha 0.5",\
"< cat doubling_the_cache.dat | awk '{if ($3==0.0001 && $2==0.8) print $0} '" using 1:4 with lines title "alpha 0.8",\
"< cat doubling_the_cache.dat | awk '{if ($3==0.0001 && $2==1) print $0} '" using 1:4 with lines title "alpha 1",\
"< cat doubling_the_cache.dat | awk '{if ($3==0.0001 && $2==1.2) print $0} '" using 1:4 with lines title "alpha 1.2"

set key off
set title "c2ctlg 1e-3"
unset ylabel

plot "< cat doubling_the_cache.dat | awk '{if ($3==0.001 && $2==0) print $0} '" using 1:4 with lines title "alpha 0" ,\
"< cat doubling_the_cache.dat | awk '{if ($3==0.001 && $2==0.5) print $0} '" using 1:4 with lines title "alpha 0.5",\
"< cat doubling_the_cache.dat | awk '{if ($3==0.001 && $2==0.8) print $0} '" using 1:4 with lines title "alpha 0.8",\
"< cat doubling_the_cache.dat | awk '{if ($3==0.001 && $2==1) print $0} '" using 1:4 with lines title "alpha 1",\
"< cat doubling_the_cache.dat | awk '{if ($3==0.001 && $2==1.2) print $0} '" using 1:4 with lines title "alpha 1.2"


set title "c2ctlg 1e-2"

plot "< cat doubling_the_cache.dat | awk '{if ($3==0.01 && $2==0) print $0} '" using 1:4 with lines title "alpha 0" ,\
"< cat doubling_the_cache.dat | awk '{if ($3==0.01 && $2==0.5) print $0} '" using 1:4 with lines title "alpha 0.5",\
"< cat doubling_the_cache.dat | awk '{if ($3==0.01 && $2==0.8) print $0} '" using 1:4 with lines title "alpha 0.8",\
"< cat doubling_the_cache.dat | awk '{if ($3==0.01 && $2==1) print $0} '" using 1:4 with lines title "alpha 1",\
"< cat doubling_the_cache.dat | awk '{if ($3==0.01 && $2==1.2) print $0} '" using 1:4 with lines title "alpha 1.2"
