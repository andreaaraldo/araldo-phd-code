%
N = 100000;
B = 100;
lambda_tot = 4;
alpha = 1;
TC = 31.688717870764198291331729873124;

q = 0.01; % probability to accept an incoming object

[P_zipf, lambda_obj] = prepare_zipf(N,B,lambda_tot,alpha);
[pHitChe, pHitCheAvg_LCE] = che_LCE(P_zipf, lambda_obj, TC);
pHitCheAvg_LCE

[pHitChe, pHitCheAvg_unif] = che_LCE(P_zipf, lambda_obj, TC, q);
pHitCheAvg_unif

exit
