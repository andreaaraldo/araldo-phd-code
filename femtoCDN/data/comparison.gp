metric = "hist_allocation"
ctlg="100000";
eps= "0.5"
K="1000";
totreq="1e+07";
seed="1";


method="descent";
req_per_epoch = "1e3";
file1 = sprintf("%s-ctlg_%s-eps_%s-req_per_epoch_%s-K_%s-%s-totreq_%s-seed_%s.dat", \
	metric, ctlg, eps, req_per_epoch, K, method, totreq, seed);

method="descent";
req_per_epoch = "1e6";
file2 = sprintf("%s-ctlg_%s-eps_%s-req_per_epoch_%s-K_%s-%s-totreq_%s-seed_%s.dat", \
	metric, ctlg, eps, req_per_epoch, K, method, totreq, seed);

method="dspsa";
req_per_epoch = "1e3";
file3 = sprintf("%s-ctlg_%s-eps_%s-req_per_epoch_%s-K_%s-%s-totreq_%s-seed_%s.dat", \
	metric, ctlg, eps, req_per_epoch, K, method, totreq, seed);

# hist_allocation-ctlg_100000-eps_0.5-req_per_epoch_1e3-K_1000-dspsa-totreq_1e+07-seed_1.dat

method="dspsa";
req_per_epoch = "1e6";
file4 = sprintf("%s-ctlg_%s-eps_%s-req_per_epoch_%s-K_%s-%s-totreq_%s-seed_%s.dat", \
	metric, ctlg, eps, req_per_epoch, K, method, totreq, seed);


set terminal postscript eps color
set output sprintf("%s.eps", file1)
set key outside

set xlabel "Epoch"
set ylabel metric


plot \
file1 using 1:2 title "descent 1e3" with linespoints, \
file2 using 1:2 title "descent 1e6" with linespoints,\
file3 using 1:2 title "dspsa 1e3" with linespoints, \
file4 using 1:2 title "dspsa 1e6" with linespoints,\


