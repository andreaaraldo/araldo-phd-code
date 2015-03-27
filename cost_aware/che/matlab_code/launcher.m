%
N = 50
cache_size = 10;
alpha = 1;
q = 0.01; % probability to accept an incoming object
lambda_tot = 100;
policy='LCE'


[P_zipf, lambda_obj] = prepare_zipf(N,cache_size,lambda_tot,alpha);

TC = compute_TC(N, cache_size, lambda_tot, P_zipf,policy)
f_name = sprintf('TC-ctlg_%g-csize_%g-alpha_%g-lambda_tot_%g.dat', N, cache_size, alpha, lambda_tot);
fid = fopen(f_name,'w');  
if fid ~= -1
  fprintf(fid, '%g\n',TC);
  fclose(fid);
else
	error('Error in opening file');
end

[pHitChe, pHitCheAvg] = che_LCE(P_zipf, lambda_obj, TC, policy);

