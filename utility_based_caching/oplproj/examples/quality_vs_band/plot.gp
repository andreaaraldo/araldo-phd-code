set terminal postscript eps enhanced color font "Times-Roman" 32
set output "results.eps"

set size 2,1;

set style data histogram;
set style histogram cluster gap 5;
set style fill solid border -1
set boxwidth 0.9
set xtic rotate by -45 scale 0
set xlabel "peering link capacity"
set ylabel "number of cached copies"
set key top outside

plot "results.dat" \
	using 7:xtic(1) title "q=1",\
  ''using 8:xtic(1) title "q=2",\
  ''using 9:xtic(1) title "q=3"\
;
