set terminal postscript eps mono
set output "long_run.eps";
lambda=1e4

set grid y

set yrange [0:70]
set ylabel "slots to CP 1"
plot \
"dspsa_orig_3e3h_nocoeff.dat" u ($1/(lambda*3600 )):2 title "ZSDSPSA nocoeff" pointtype 31 pointsize 0.1,\
"dspsa_orig_3e3h_coeff.dat" u ($1/(lambda*3600 )):2 title "ZSDSPSA coeff" pointtype 31 pointsize 0.1,\
"" u ($1/(lambda*3600 )):(64) with lines title "OPT",\

