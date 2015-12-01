set terminal postscript eps enhanced  mono
set output "config.eps";
opt_Eh = 38.682 
opt_all = 64;

set multiplot layout 2,2
set linestyle 1 linecolor rgb"black" linetype -1
set linestyle 2 linecolor rgb"grey" linetype -1
set linestyle 3 linecolor rgb"#e5e5e5" linetype -1
set xlabel "hours"
set key off



lambda=1e1;

set yrange [0:70]
set ylabel "slots to CP 1\n {/Symbol l}=10 req/s"
plot "lambda_1e1.dat"\
   u ($1/(lambda*3600 )):2 title "original " with lines ls 1,\
"" u ($1/(lambda*3600 )):5 title "improved not proved" with lines ls 2,\
"" u ($1/(lambda*3600 )):8 title "improved proved" with lines ls 3,\
"" u ($1/(lambda*3600 )):(opt_all) with lines title "OPT" linecolor rgb"black" linetype -1


lambda=1e2;

set yrange [0:70]
set ylabel "slots to CP 1\n {/Symbol l}=100 req/s"
plot "lambda_1e2.dat"\
   u ($1/(lambda*3600 )):2 title "original " with lines ls 1,\
"" u ($1/(lambda*3600 )):5 title "improved not proved" with lines ls 2,\
"" u ($1/(lambda*3600 )):8 title "improved proved" with lines ls 3,\
"" u ($1/(lambda*3600 )):(opt_all) with lines title "OPT" linecolor rgb"black" linetype -1


lambda=1e3;

set yrange [0:70]
set ylabel "slots to CP 1\n {/Symbol l}=1000 req/s"
plot "lambda_1e3.dat"\
   u ($1/(lambda*3600 )):2 title "original " with lines ls 1,\
"" u ($1/(lambda*3600 )):5 title "improved not proved" with lines ls 2,\
"" u ($1/(lambda*3600 )):8 title "improved proved" with lines ls 3,\
"" u ($1/(lambda*3600 )):(opt_all) with lines title "OPT" linecolor rgb"black" linetype -1



lambda=1e8;
set key bottom

set yrange [0:70]
set ylabel "slots to CP 1\n {/Symbol l}=1e8 req/s"
plot "lambda_1e8.dat"\
   u ($1/(lambda*3600 )):2 title "original " with lines ls 1,\
"" u ($1/(lambda*3600 )):5 title "improved not proved" with lines ls 2,\
"" u ($1/(lambda*3600 )):8 title "improved proved" with lines ls 3,\
"" u ($1/(lambda*3600 )):(opt_all) with lines title "OPT" linecolor rgb"black" linetype -1

