function v = compute_value(in, theta)
	v = 0;
	for j=1:in.p
			estimated_rank = [];
			if in.know < Inf
				% If each CP knows exactly the popularity of its catalog,
				% we do not need the estimated_rank data structure for our computation
				estimated_rank = in.estimated_rank(j,:)';
			end

		[cdf_value, h] = ZipfCDF_smart(floor(theta(j) ), 0, [], in.alpha(j), [], in.ctlg(j), estimated_rank );
		v += cdf_value * in.req_proportion(j);
	end
end
