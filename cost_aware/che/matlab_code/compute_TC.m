function TC = compute_TC(N, cache_size, lambda_tot, P_zipf, policy_)

	lambda_obj = zeros(1,N);
	for i=1:N
		lambda_obj(1,i) = P_zipf(1,i) * lambda_tot;
	end

	TC = 0;
	switch policy_
		case 'LRU'
			syms x;
			TC = solve(sum(1-exp(-lambda_obj(1,1:N).*x)) == cache_size);
		case 'MID'
			syms x;
			TC = solve(sum( ( 1-exp(-lambda_obj(1,1:N).*x) )/(1-exp(-lambda_obj(1,1:N).*x) - exp(-lambda_obj(1,1:N).*(x/2) ))  ) == cache_size);
		otherwise
			error('Policy not valid');
	end

	fid = fopen(fname,'w');  
end
