function TC = compute_TC(N, cache_size, lambda_tot, P_zipf)

	lambda_obj = zeros(1,N);
	for i=1:N
		lambda_obj(1,i) = P_zipf(1,i) * lambda_tot;
	end

	TC = 0;
	syms x;
	TC = solve(sum(1-exp(-lambda_obj(1,1:N).*x)) == cache_size);
end
