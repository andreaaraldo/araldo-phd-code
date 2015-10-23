metric = "hist_allocation"
req = "2e6";
effort = "0.01";
plotname = sprintf("%s-%s_req-effort_%s", metric, req, effort);

#opt_allocation_req_2e3_effort_equal = 0.54000;
#opt_hit_req_2e3_effort_equal = 0.46531;
#opt_hit_req_2e6_effort_0.01 = 0.38512;
#opt_allocation_req_2e6_effort_0.01 = 0.79;

opt = 0.79;


set terminal postscript eps color
set output sprintf("%s.eps", plotname)
set key outside

set xlabel "Epoch"
set ylabel metric


plot sprintf("%s.dat", plotname) \
	using 0:1 title "descent" with lines,\
""	using 0:2 title "dspsa original" with lines,\
""	using 0:3 title "dspsa enhanced" with lines,\
""	using 0:(opt) title "OPT" with lines


