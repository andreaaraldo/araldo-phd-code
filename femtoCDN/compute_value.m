function v = compute_value(in, theta)
	v = 0;
	for j=1:in.p
		[cdf_value, h] = ZipfCDF_smart(floor(theta(j) ), 0, [], in.alpha(j), [], in.ctlg(j) );
		cdf_value
		v += cdf_value * in.req_proportion(j);
	end
end
