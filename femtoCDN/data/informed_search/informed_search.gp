set terminal postscript eps enhanced color
set output "informed_search.eps"

set multiplot layout 2,2

set xlabel "req eps"

plot "varying_req.dat"\
	u 8:11 with points title "unif",\
""	u 8:10 with points title "opt"

set xlabel "alpha eps"

plot "varying_alpha_eps.dat"\
	u 7:11 with points title "unif",\
""	u 7:10 with points title "opt"

set xlabel "alpha0"

plot "varying_alpha0.dat"\
	u 6:11 with points title "unif",\
""	u 6:10 with points title "opt"

set xlabel "ctlg_eps"

plot "varying_ctlg_eps.dat"\
	u 3:11 with points title "unif",\
""	u 3:10 with points title "opt"
