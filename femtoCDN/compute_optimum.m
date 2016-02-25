function theta_opt = compute_optimum(in)
	border=ones(in.p,1);
	border_frequencies = harmonic_num = last_cdf_values = zeros(in.p,1);
	for j=1:in.p
		[cdf_value, harmonic_num_returned] = ZipfCDF_smart(border(j), 0, [], in.alpha(j), [], in.catalog(j));
		last_cdf_values(j) = cdf_value;
		border_frequencies(j) = cdf_value * in.req_proportion(j);
		harmonic_num(j)= harmonic_num_returned;
	end
	border_frequencies


	for i=1:in.K
		[border_pop, idx] = max(border_frequencies);
		frequenze_bordo = border_frequencies'
		massimo_is = idx
		[cdf_value, harmonic_num_returned] = ZipfCDF_smart(border(idx)+1, border(idx), last_cdf_values(idx), ...
				in.alpha(idx), harmonic_num(idx), in.catalog(idx));
		border(idx)++;
		border_frequencies(idx) = (cdf_value - last_cdf_values(idx) )* in.req_proportion(idx);
		last_cdf_values(idx) = cdf_value;
	end%for

	theta_opt = border .- ones(in.p,1);
end




%%% The rest is just for verification
addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");

alpha=0.8;
single_ctlg = 5;
in.K=10;
in.req_proportion = [0.4 0.3 0.2 0.1]';
in.p = length(in.req_proportion);
in.alpha = repmat(alpha, in.p,1);
in.catalog = repmat(single_ctlg, in.p, 1);

[ pdf, harmonic_num ] = ZipfPDF( alpha, single_ctlg );
pdf'

theta_opt = compute_optimum(in)
