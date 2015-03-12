%
N = 100000;
cache_size = 100;
alpha = 1;
q = 0.01; % probability to accept an incoming object
TC = 31.688717870764198291331729873124;
lambda_tot = 100;


[P_zipf, lambda_obj] = prepare_zipf(N,cache_size,lambda_tot,alpha);

TC = compute_TC(N, cache_size, lambda_tot, P_zipf);
f_name = sprintf('TC-ctlg_%g-csize_%g-alpha_%g-lambda_tot_%g.dat', N, cache_size, alpha, lambda_tot);
fid = fopen(f_name,'w');  
if fid ~= -1
  fprintf(fid, '%g\n',TC);
  fclose(fid);
else
	error('Error in opening file');
end

	
exit

[pHitChe, pHitCheAvg_LCE] = che_LCE(P_zipf, lambda_obj, TC);
pHitCheAvg_LCE

[pHitChe, pHitCheAvg_unif] = che_unif(P_zipf, lambda_obj, TC, q);
pHitCheAvg_unif

exit
