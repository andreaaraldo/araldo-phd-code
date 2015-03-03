%
N = 100000;
B = 100;
alpha = 1;
q = 0.01; % probability to accept an incoming object
TC = 31.688717870764198291331729873124;


for lambda_tot = [1, 100]
	a=5;
	f_name = sprintf('TC-ctlg_%g-csize_%g-alpha_%g-lambda_tot_%g.dat', N, B, alpha, lambda_tot)

	

	[P_zipf, lambda_obj] = prepare_zipf(N,B,lambda_tot,alpha);

	[pHitChe, pHitCheAvg_LCE] = che_LCE(P_zipf, lambda_obj, TC);
	pHitCheAvg_LCE

	[pHitChe, pHitCheAvg_unif] = che_unif(P_zipf, lambda_obj, TC, q);
	pHitCheAvg_unif
end



exit
