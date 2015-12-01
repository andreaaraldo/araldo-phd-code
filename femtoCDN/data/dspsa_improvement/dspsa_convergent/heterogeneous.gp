set terminal postscript eps enhanced  mono
set output "heterogeneous2.eps";
opt_Eh = 0
opt_all = 64;

set linestyle 1 linecolor rgb"black" linetype -1
set linestyle 2 linecolor rgb"grey" linetype -1
set linestyle 3 linecolor rgb"#e5e5e5" linetype -1
set xlabel "hours"

set yrange [0.25:0.38]

lambda=1e2;

set ylabel "slots to CP 1\n {/Symbol l}=10 req/s"
plot "heterogeneous2.dat"\
   u ($1/(lambda*3600 )):3 title "original " with lines ls 1,\
"" u ($1/(lambda*3600 )):6 title "improved not proved" with lines ls 2,\
"" u ($1/(lambda*3600 )):9 title "improved proved" with lines ls 3,\
"" u ($1/(lambda*3600 )):(opt_Eh) with lines title "OPT" linecolor rgb"black" linetype -1


