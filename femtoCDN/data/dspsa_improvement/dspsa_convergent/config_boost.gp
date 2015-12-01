set terminal postscript eps enhanced  mono
set output "config_boost.eps";
opt_Eh = 38.682 
opt_all = 64;

set linestyle 1 linecolor rgb"black" linetype -1
set linestyle 2 linecolor rgb"grey" linetype -1
set linestyle 3 linecolor rgb"#e5e5e5" linetype -1
set xlabel "hours"



lambda=1e2;

set yrange [0:70]
set ylabel "slots to CP 1\n {/Symbol l}=10 req/s"
plot "boost2_coeff10.dat"\
   u ($1/(lambda*3600 )):2 title "original " with lines ls 1,\
"" u ($1/(lambda*3600 )):5 title "improved not proved" with lines ls 2,\
"" u ($1/(lambda*3600 )):8 title "improved proved" with lines ls 3,\
"" u ($1/(lambda*3600 )):(opt_all) with lines title "OPT" linecolor rgb"black" linetype -1


