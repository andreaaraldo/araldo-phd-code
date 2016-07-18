set terminal postscript eps color
tot_req="1e6"
lambda=92.5926

set output sprintf("comparison_tot_req_%s.eps", tot_req);
set key outside

set yrange [0:80]
set xlabel "minutes"

set label "expected hit ratio = 33%" at 185,19
set label "expected hit ratio = 37%" at 185,45

plot \
sprintf("tot_req_%s/descent_ep1e1.dat", tot_req) u ($1/(lambda*60 )):2 title "descent T=1080s" with points, \
sprintf("tot_req_%s/descent_ep1e2.dat", tot_req) 	u ($1/(lambda*60 )):2 title "descent T=108s" with points, \
sprintf("tot_req_%s/descent_ep1e3.dat", tot_req)	u ($1/(lambda*60 )):2 title "descent T=10.8s" with points, \
sprintf("tot_req_%s/descent_ep1e4.dat", tot_req)	u ($1/(lambda*60 )):2 title "descent T=1.08s" with points, \
sprintf("tot_req_%s/dspsa_ep1e1.dat", tot_req)	u ($1/(lambda*60 )):2 title "dspsa T=1080s" with points, \
sprintf("tot_req_%s/dspsa_ep1e2.dat", tot_req)	u ($1/(lambda*60 )):2 title "dspsa T=108s" with points, \
sprintf("tot_req_%s/dspsa_ep1e3.dat", tot_req)	u ($1/(lambda*60 )):2 title "dspsa T=10.8s" with points, \
sprintf("tot_req_%s/dspsa_ep1e4.dat", tot_req)	u ($1/(lambda*60 )):2 title "dspsa T=1.08s" with points, \
sprintf("tot_req_%s/optimum.dat", tot_req) u ($1/(lambda*60 )):2 title "optimum" with lines


