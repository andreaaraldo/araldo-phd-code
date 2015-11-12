set terminal postscript eps color
set output "improvement.eps";
lambda=1e4

set multiplot layout 4,2
set key bottom

set grid y

set yrange [0:70]
set ylabel "slots to CP 1"
plot \
"dspsa_original.dat" u ($1/(lambda*3600 )):2 title "ZSDSPSA" pointtype 31 pointsize 0.1,\
"" u ($1/(lambda*3600 )):(64) with lines title "OPT",\


set autoscale
set ylabel "delta vc for CP 1"
plot \
"dspsa_original.dat" u  ($1/(lambda*3600 )):(-$3) notitle  pointtype 31 pointsize 0.001,\


set autoscale x
set yrange [0:70]
set ylabel "slots to CP 1"
plot \
"dspsa_enhanced.dat" u ($1/(lambda*3600 )):2 title "EZSDSPSA" pointtype 31 pointsize 0.1,\
"" u ($1/(lambda*3600 )):(64) with lines title "OPT",\


set ylabel "delta vc for CP 1"
set yrange [-1.4:1.4]
set ylabel "delta vc for CP 1"
plot \
"dspsa_enhanced.dat" u  ($1/(lambda*3600 )):($3+ rand(0)*0.2 ) notitle pointtype 31 pointsize 0.0001,\



set xrange [0:3]
set yrange [0:70]
set ylabel "slots to CP 1"
plot \
"dspsa_enhanced.dat" u ($1/(lambda*3600 )):2 title "EZSDSPSA" pointtype 31 pointsize 0.1,\
"" u ($1/(lambda*3600 )):(64) with lines title "OPT",\

set yrange [-1.4:1.4]
set ylabel "delta vc for CP 1"
plot \
"dspsa_enhanced.dat" u  ($1/(lambda*3600 )):($3+ rand(0)*0.2 ) notitle pointtype 31 pointsize 0.1,\

set xlabel "hours"

set autoscale x
set yrange[25:40]
set ylabel "E[h]"
plot \
"dspsa_original.dat" u ($1/(lambda*3600 )):($4*100) title "ZSDSPSA"  pointtype 31 pointsize 0.1,\
"" u ($1/(lambda*3600 )):(38.682) with lines title "OPT",\


set ylabel "E[h]"
plot \
"dspsa_enhanced.dat" u ($1/(lambda*3600 )):($4*100) title "EZSDSPSA"  pointtype 31 pointsize 0.1,\
"" u ($1/(lambda*3600 )):(38.682) with lines title "OPT",\

