set terminal postscript eps enhanced  mono
set output "dspsa_convergent.eps";
opt_Eh = 38.682 
opt_all = 64;

set multiplot layout 2,1
set linestyle 1 linecolor rgb"black"
set linestyle 2 linecolor rgb"grey"
set linestyle 3 linecolor rgb"black" linetype 2
set xlabel "hours"
set key bottom



lambda=100;
filename="dspsa_convergent.dat";

set yrange [0:70]
set ylabel "slots to CP 1\n {/Symbol l}=100 req/s"
plot \
filename u ($1/(lambda*3600 )):2 title "original " with lines ls 1,\
"" u ($1/(lambda*3600 )):5 title "improved not proved" with lines ls 2,\
"" u ($1/(lambda*3600 )):8 title "improved proved" with lines ls 3,\
"" u ($1/(lambda*3600 )):(opt_all) with lines title "OPT" linecolor rgb"black" linetype -1

