set terminal postscript eps enhanced color
set output "link_load.eps"
set size 1,0.5

set xtics ("0.25" -1, "0.5" 0, "1" 1, "2" 2, "3" 3, "4" 4, "5" 5, "6" 6, "7" 7, "8" 8);
set key top outside


bw = 0.1; # boxwidth
set boxwidth 0.1
set style fill solid

set xlabel "request load";
set ylabel "link load %"

plot 'link_load.dat' \
	using ($1+0*bw):($2==1?$3*100:1/0) with boxes title "load on left leaf link",\
''	using ($1+1*bw):($2==2?$3*100:1/0) with boxes title "load on right leaf link",\
''	using ($1+2*bw):($2==3?$3*100:1/0) with boxes title "load on server link";
