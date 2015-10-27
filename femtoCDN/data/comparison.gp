metric = "hist_allocation"
ctlg="1e5";
eps= "0.5"
K="1e3";
totreq="1e6";
seed="1";


method="dspsa_orig";
req_per_epoch = "1e2";
file1 = sprintf("%s-ctlg_%s-eps_%s-req_per_epoch_%s-K_%s-%s-totreq_%s-seed_%s.dat", \
	metric, ctlg, eps, req_per_epoch, K, method, totreq, seed);



method="dspsa_orig";
req_per_epoch = "1e3";
file2 = sprintf("%s-ctlg_%s-eps_%s-req_per_epoch_%s-K_%s-%s-totreq_%s-seed_%s.dat", \
	metric, ctlg, eps, req_per_epoch, K, method, totreq, seed);

method="optimum";
req_per_epoch = "1e2";
file3 = sprintf("%s-ctlg_%s-eps_%s-req_per_epoch_%s-K_%s-%s-totreq_%s-seed_%s.dat", \
	metric, ctlg, eps, req_per_epoch, K, method, totreq, seed);


set terminal postscript eps color
set output sprintf("%s.eps", file1)
set key outside

print sprintf("%s.eps", file1);

set xlabel "Epoch"
set ylabel metric


plot \
file1 using 1:2 title "descent 1e2" with linespoints, \
file2 using 1:2 title "descent 1e3" with linespoints,\
file3 using 1:2 title "optimum" with lines

