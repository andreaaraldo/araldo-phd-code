function v = compute_value(in, c)
	tot_lambdatau = 0;
	for j=1:in.N
		tot_lambdatau += sum( in.lambdatau(j,1:c(j) ) );
	end
	v = tot_lambdatau / sum(in.R);
end
