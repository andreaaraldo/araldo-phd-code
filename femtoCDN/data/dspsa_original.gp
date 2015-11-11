set terminal postscript eps color
set output "dspsa_original.eps";
lambda=1e4

set multiplot layout 1,2
set yrange [0:80]
set key outside


set xlabel "hours"
set ylabel "slots to CP 1"


plot \
"dspsa_original.dat" u ($1/(lambda*3600 )):2 title "dspsa",\
"" u ($1/(lambda*3600 )):(64) with lines title "optimum",\


set ylabel "delta vc for CP 1"
set autoscale
plot \
"dspsa_original.dat" u  ($1/(lambda*3600 )):(-$3) notitle,\

