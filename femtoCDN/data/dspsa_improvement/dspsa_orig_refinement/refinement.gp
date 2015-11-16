set terminal postscript eps color
set output "refinement.eps";
lambda=1e4
set key bottom

set grid y

set yrange [0:70]
set ylabel "slots to CP 1"
plot \
"dspsa_orig-norm_1-no-30h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA no coeff " pointsize 1,\
"dspsa_orig-norm_1-simple-30h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA simple coeff " pointsize 1,\
"dspsa_orig-norm_1-every10-30h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA coeff/10 " pointsize 1,\
"dspsa_orig-norm_1-every100-30h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA coeff/100 " pointsize 1,\
"" u ($1/(lambda*3600 )):(64) with lines title "OPT",\

