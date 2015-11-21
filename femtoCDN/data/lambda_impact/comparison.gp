set terminal postscript eps mono
set output "lambda_impact.eps";
opt_Eh = 0.38682
opt_all = 64;

set multiplot layout 3,2


set key bottom

set xlabel "hours"
lambda=1000;
en_file=sprintf("data/rawdata/coeff/N_10-ctlg_1e+05-ctlg_eps_0-ctlg_perm_1-alpha0_1-alpha_eps_0-lambda_%g-req_prop_0.64_0.04_0.04_0.04_0.04_0.04_0.04_0.04_0.04_0.04-R_perm_1-T_1e+02-K_1e+02-dspsa_enhanced-norm_0-coeff_no-tot_time_300-seed_1.dat",lambda);
orig_file=sprintf("data/rawdata/coeff/N_10-ctlg_1e+05-ctlg_eps_0-ctlg_perm_1-alpha0_1-alpha_eps_0-lambda_%g-req_prop_0.64_0.04_0.04_0.04_0.04_0.04_0.04_0.04_0.04_0.04-R_perm_1-T_1e+02-K_1e+02-dspsa_orig-norm_1-coeff_every100-tot_time_300-seed_1.dat",lambda);

set yrange [0:70]
set ylabel "slots to CP 1"
plot \
orig_file u ($1/(lambda*3600 )):2 title "NZSDSPSA " pointsize 0.3 with lines,\
en_file u ($1/(lambda*3600 )):2 title "EZSDSPSA " pointsize 0.3 with lines,\
"" u ($1/(lambda*3600 )):(opt_all) with lines title "OPT" linecolor rgb"black" linetype -1,\

set autoscale
set ylabel "E[h]"
plot \
orig_file u ($1/(lambda*3600 )):3 title "NZSDSPSA " pointsize 0.3 with lines,\
en_file u ($1/(lambda*3600 )):3 title "EZSDSPSA " pointsize 0.3 with lines,\
"" u ($1/(lambda*3600 )):(opt_Eh) with lines title "OPT" linecolor rgb"black" linetype -1,\
