function v = compute_value(in, c)
	tot_lambda = 0;
	for j=1:in.N
		tot_lambda += sum( in.lambda(j,1:c(j) ) );
	end
	v = tot_lambda / sum(in.R);
end
