set terminal postscript eps enhanced color
set output "informed_search.eps"

set key box bottom

set yrange [0:80]

set multiplot layout 2,2 title "Hit Ratio % in different scenarios"

set xlabel "R_1 / R_2"
set xtics ("0.5/0.5" 0, "0.4/0.6" 0.2, "0.3/0.7" 0.4, "0.2/0.8" 0.6, "0.1/0.9" 0.8, "0/1" 1) rotate by -90;

plot "varying_req.dat"\
	u 8:11 with points title "unif",\
""	u 8:10 with points title "opt"

set key off

set xlabel "alpha1/alpha2"
set xtics ("1/1" 0, "0.8/1.2" 0.2, "0.6/1.4" 0.4, "0.4/1.6" 0.6, "0.2/1.8" 0.8, "1/2" 1);

plot "varying_alpha_eps.dat"\
	u 7:11 with points title "unif",\
""	u 7:10 with points title "opt"

set xlabel "alpha1/alpha2"
set xtics ("0.20/0.31" 0.25, "0.38/0.63" 0.50, "0.56/0.93" 0.75, "0.75/1.25" 1) rotate by -90;

plot "varying_alpha0.dat"\
	u 6:11 with points title "unif",\
""	u 6:10 with points title "opt"

set xlabel "ctlg1/ctlg2"
set xtics ("1e5/1e5" 0, "8e4/12e4" 0.2, "6e4/14e4" 0.4, "4e4/16e4" 0.6, "2e4/18e4" 0.8, "1e5/0" 1) rotate by -90;

plot "varying_ctlg_eps.dat"\
	u 3:11 with points title "unif",\
""	u 3:10 with points title "opt"
