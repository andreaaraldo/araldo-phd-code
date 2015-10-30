metric = "hist_allocation"
ctlg="1e+05";
alpha0="0.7"
eps= "0.2"
K="1e+02";
totreq="1e+08";
seed="1";
method="dspsa_orig";


epochs="1e+01"
file1 = sprintf("%s-ctlg_%s-alpha0_%s-eps_%s-epochs_%s-K_%s-%s-totreq_%s-seed_%s.dat", \
	metric, ctlg, alpha0, eps, epochs, K, method, totreq, seed);

epochs="1e+02"
file2 = sprintf("%s-ctlg_%s-alpha0_%s-eps_%s-epochs_%s-K_%s-%s-totreq_%s-seed_%s.dat", \
	metric, ctlg, alpha0, eps, epochs, K, method, totreq, seed);

epochs="1e+03"
file3 = sprintf("%s-ctlg_%s-alpha0_%s-eps_%s-epochs_%s-K_%s-%s-totreq_%s-seed_%s.dat", \
	metric, ctlg, alpha0, eps, epochs, K, method, totreq, seed);


method="optimum";
fileopt = sprintf("%s-ctlg_%s-alpha0_%s-eps_%s-epochs_%s-K_%s-%s-totreq_%s-seed_%s.dat", \
	metric, ctlg, alpha0, eps, epochs, K, method, totreq, seed);


set terminal postscript eps color
set output sprintf("%s.eps", file1)
set key outside

print sprintf("%s.eps", file1);

set xlabel "Epoch"
set ylabel metric


plot \
file1 using 1:2 title "dspsa 1e1 epochs" with linespoints, \
file2 using 1:2 title "dspsa 1e2 epochs" with linespoints,\
file3 using 1:2 title "dspsa 1e3 epochs" with linespoints,\
fileopt using 1:2 title "optimum" with linespoints

