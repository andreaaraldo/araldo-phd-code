set terminal postscript eps enhanced color
set output "cache_sizes.eps"

total_cache = 712.50; #MB

bw = 0.1; # boxwidth
set boxwidth 0.1
set style fill solid

set xlabel "request load"
set ylabel "fraction of cache space %"

plot 'cache_sizes.dat' \
	using ($1+0*bw):($2==1?$3*100/total_cache:1/0) with boxes title "cache size of node 1",\
''	using ($1+1*bw):($2==2?$3*100/total_cache:1/0) with boxes title "cache size of node 2",\
''	using ($1+2*bw):($2==3?$3*100/total_cache:1/0) with boxes title "cache size of node 3";

