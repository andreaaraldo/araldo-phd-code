%
N = 20;
cache_size = 2;
alpha = 1;
q = 0.01; % probability to accept an incoming object
lambda_tot = 100;
policy='MID';
TC_LCE = 0.02274911140384644773459557480524;
%TC = TC_LCE;


[P_zipf, lambda_obj] = prepare_zipf(N,cache_size,lambda_tot,alpha);
disp('Computing TC\n');
TC = compute_TC(N, cache_size, lambda_tot, P_zipf,policy)

%f_name = sprintf('TC-ctlg_%g-csize_%g-alpha_%g-lambda_tot_%g.dat', N, cache_size, alpha, lambda_tot);
%fid = fopen(f_name,'w');  
%if fid ~= -1
%  fprintf(fid, '%g\n',TC);
%  fclose(fid);
%else
%	error('Error in opening file');
%end

[pHitChe, pHitCheAvg] = hit(P_zipf, lambda_obj, TC, q, policy);
pHitCheAvg

