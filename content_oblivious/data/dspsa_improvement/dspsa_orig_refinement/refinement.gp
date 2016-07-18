set terminal postscript eps color
set output "refinement.eps";
lambda=1e4
opt_Eh = 0.38682

set multiplot layout 2,2


set key bottom

set xlabel "hours"
set yrange [0:70]
set ylabel "slots to CP 1"
plot \
"dspsa_orig-norm_1-no-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA no coeff " pointsize 0.3 with points,\
"dspsa_orig-norm_1-simple-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA F=1 " pointsize 0.3 with points,\
"dspsa_orig-norm_1-every10-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA F=10 " pointsize 0.3 with points,\
"dspsa_orig-norm_1-every100-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA F=100 " pointsize 0.3 with points,\
"dspsa_enhanced-norm_0-no-300h.dat" u ($1/(lambda*3600 )):2 title "EZSDSPSA " pointsize 0.3 with points,\
"" u ($1/(lambda*3600 )):(64) with lines title "OPT" linecolor rgb"black" linetype -1,\


set yrange [0.3:0.4]
set ylabel "E[h]"
plot \
"Eh_dspsa_orig-norm_1-no-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA no coeff " pointsize 0.3 with lines,\
"Eh_dspsa_orig-norm_1-simple-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA F=1 " pointsize 0.3 with lines,\
"Eh_dspsa_orig-norm_1-every10-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA F=10 " pointsize 0.3 with lines,\
"Eh_dspsa_orig-norm_1-every100-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA F=100 " pointsize 0.3 with lines,\
"Eh_dspsa_enhanced-norm_0-no-300h.dat" u ($1/(lambda*3600 )):2 title "EZSDSPSA " pointsize 0.3 with lines,\
"" u ($1/(lambda*3600 )):(opt_Eh) with lines title "OPT" linecolor rgb"black" linetype -1,\

set key off
set xrange [0:1]

set yrange [0:70]
set ylabel "slots to CP 1"
plot \
"dspsa_orig-norm_1-no-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA no coeff " pointsize 0.3 with points,\
"dspsa_orig-norm_1-simple-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA simple coeff " pointsize 0.3 with points,\
"dspsa_orig-norm_1-every10-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA coeff/10 " pointsize 0.3 with points,\
"dspsa_orig-norm_1-every100-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA coeff/100 " pointsize 0.3 with points,\
"dspsa_enhanced-norm_0-no-300h.dat" u ($1/(lambda*3600 )):2 title "EZSDSPSA " pointsize 0.3 with points,\
"" u ($1/(lambda*3600 )):(64) with lines title "OPT" linecolor rgb"black" linetype -1,\


set yrange [0.3:0.4]
set ylabel "E[h]"
plot \
"Eh_dspsa_orig-norm_1-no-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA no coeff " pointsize 0.3 with lines,\
"Eh_dspsa_orig-norm_1-simple-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA simple coeff " pointsize 0.3 with lines,\
"Eh_dspsa_orig-norm_1-every10-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA coeff/10 " pointsize 0.3 with lines,\
"Eh_dspsa_orig-norm_1-every100-300h.dat" u ($1/(lambda*3600 )):2 title "NZSDSPSA coeff/100 " pointsize 0.3 with lines,\
"Eh_dspsa_enhanced-norm_0-no-300h.dat" u ($1/(lambda*3600 )):2 title "EZSDSPSA " pointsize 0.3 with lines,\
"" u ($1/(lambda*3600 )):(opt_Eh) with lines title "OPT" linecolor rgb"black" linetype -1,\

