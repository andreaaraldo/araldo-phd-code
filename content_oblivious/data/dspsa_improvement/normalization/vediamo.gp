set terminal postscript eps enhanced  mono
set output "vediamo.eps";
opt_Eh = 0.36395
opt_all = 64;

set linestyle 1 linecolor rgb"black" linetype -1
set linestyle 2 linecolor rgb"grey" linetype -1
set linestyle 3 linecolor rgb"#e5e5e5" linetype -1
set xlabel "hours"

set yrange [0.25:0.38]

set multiplot layout 3,1
set key off

lambda=10;

set ylabel sprintf("slots to CP 1\n {/Symbol l}=%greq/s", lambda);
plot sprintf("lambda%g.dat",lambda) \
   u ($1/(lambda*3600 )):3 title "original " with lines ls 1,\
"" u ($1/(lambda*3600 )):6 title "improved not proved" with lines ls 2,\
"" u ($1/(lambda*3600 )):9 title "improved proved" with lines ls 3,\
"" u ($1/(lambda*3600 )):(opt_Eh) with lines title "OPT" linecolor rgb"black" linetype -1




lambda=100;

set ylabel sprintf("slots to CP 1\n {/Symbol l}=%greq/s", lambda);
plot sprintf("lambda%g.dat",lambda) \
   u ($1/(lambda*3600 )):3 title "original " with lines ls 1,\
"" u ($1/(lambda*3600 )):6 title "improved not proved" with lines ls 2,\
"" u ($1/(lambda*3600 )):9 title "improved proved" with lines ls 3,\
"" u ($1/(lambda*3600 )):(opt_Eh) with lines title "OPT" linecolor rgb"black" linetype -1



set key bottom
lambda=1000;

set ylabel sprintf("slots to CP 1\n {/Symbol l}=%greq/s", lambda);
plot sprintf("lambda%g.dat",lambda) \
   u ($1/(lambda*3600 )):3 title "original " with lines ls 1,\
"" u ($1/(lambda*3600 )):6 title "improved not proved" with lines ls 2,\
"" u ($1/(lambda*3600 )):9 title "improved proved" with lines ls 3,\
"" u ($1/(lambda*3600 )):(opt_Eh) with lines title "OPT" linecolor rgb"black" linetype -1


