%
addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
ctlgs = [1e1];
c2ctlgs = [1e-1];
alphas = [1];

for ctlg=ctlgs
for alpha=alphas
	zipf = ZipfPDF(alpha, ctlg);
	
	for c2ctlg=c2ctlgs
		K = ctlg*c2ctlg;
		single_hit = sum( zipf(1:K) );
		gain = sum( zipf(K+1:2*K) );
		double_hit = single_hit+gain;
		printf("%.1g %g %.1g %g %g %g\n", ctlg, alpha, c2ctlg, gain*100, single_hit, double_hit);
	end%K
end%alpha
end%alpha
