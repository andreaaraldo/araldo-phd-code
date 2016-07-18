set terminal postscript eps enhanced  mono
set output "hit.eps";
opt_Eh = 0.38;

set multiplot layout 2,2
set linestyle 1 linecolor rgb"black" linetype -1
set linestyle 2 linecolor rgb"grey" linetype -1
set linestyle 3 linecolor rgb"#e5e5e5" linetype -1
set xlabel "hours"
set key off
set xrange [0:0.5]



lambda=1e1;

set yrange [0.1:0.4]
set ylabel "E[h]\n {/Symbol l}=10 req/s"
plot "lambda_1e1.dat"\
   u ($1/(lambda*3600 )):3 title "original " with lines ls 1,\
"" u ($1/(lambda*3600 )):6 title "improved not proved" with lines ls 2,\
"" u ($1/(lambda*3600 )):9 title "improved proved" with lines ls 3,\
"" u ($1/(lambda*3600 )):(opt_Eh) with lines title "OPT" linecolor rgb"black" linetype -1


lambda=1e2;

set ylabel "E[h]\n {/Symbol l}=100 req/s"
plot "lambda_1e2.dat"\
   u ($1/(lambda*3600 )):3 title "original " with lines ls 1,\
"" u ($1/(lambda*3600 )):6 title "improved not proved" with lines ls 2,\
"" u ($1/(lambda*3600 )):9 title "improved proved" with lines ls 3,\
"" u ($1/(lambda*3600 )):(opt_Eh) with lines title "OPT" linecolor rgb"black" linetype -1


lambda=1e3;

set ylabel "E[h]\n {/Symbol l}=1000 req/s"
plot "lambda_1e3.dat"\
   u ($1/(lambda*3600 )):3 title "original " with lines ls 1,\
"" u ($1/(lambda*3600 )):6 title "improved not proved" with lines ls 2,\
"" u ($1/(lambda*3600 )):9 title "improved proved" with lines ls 3,\
"" u ($1/(lambda*3600 )):(opt_Eh) with lines title "OPT" linecolor rgb"black" linetype -1



lambda=1e8;
set key bottom

set ylabel "E[h]\n {/Symbol l}=1e8 req/s"
plot "lambda_1e8.dat"\
   u ($1/(lambda*3600 )):3 title "original " with lines ls 1,\
"" u ($1/(lambda*3600 )):6 title "improved not proved" with lines ls 2,\
"" u ($1/(lambda*3600 )):9 title "improved proved" with lines ls 3,\
"" u ($1/(lambda*3600 )):(opt_Eh) with lines title "OPT" linecolor rgb"black" linetype -1

