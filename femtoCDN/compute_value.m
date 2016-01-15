function v = compute_value(in, theta)
	c = floor(theta);
	tot_lambdatau = 0;
	for j=1:in.p
		tot_lambdatau += sum( in.lambdatau(j,1:c(j) ) );
	end
	v = tot_lambdatau / sum(in.R);
end
