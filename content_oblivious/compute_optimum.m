%
function theta_opt = compute_optimum(in)
	addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
	if isfield(in,"theta_opt")
		theta_opt = in.theta_opt;
	elseif 	sum(in.alpha == repmat(0.8,10,1) )==10 && ...
			sum(in.req_proportion == [0.70 0 0.24 0 0.01 0.01 0.01 0.01 0.01 0.01]' )==10 && ...
			in.overall_ctlg == 1e8 & in.K == 1e6

			printf ("Optimal allocation already computed\n");
			theta_opt = [774004 0 203064 0 3822 3822 3822 3822 3822 3822]';
	else
		border=ones(in.p,1);
		border_frequencies = harmonic_num = last_cdf_values = zeros(in.p,1);
		for j=1:in.p
			estimated_rank = 1:in.ctlg(j); % For computing the optimum I use the true rank
			[cdf_value, harmonic_num_returned] = ...
				ZipfCDF_smart(border(j), 0, [], in.alpha(j), [], in.ctlg(j),
				estimated_rank);
			last_cdf_values(j) = cdf_value;
			border_frequencies(j) = cdf_value * in.req_proportion(j);
			harmonic_num(j)= harmonic_num_returned;
		end


		for i=1:in.K
			% CPidx is the identifier of a CP
			[border_pop, CPidx] = max(border_frequencies);
			estimated_rank = 1:in.ctlg(CPidx); 	% For computing the optimum 
												% I use the true rank
			[cdf_value, harmonic_num_returned] = ...
				ZipfCDF_smart(border(CPidx)+1, border(CPidx), last_cdf_values(CPidx), ...
				in.alpha(CPidx), harmonic_num(CPidx), in.ctlg(CPidx), estimated_rank);
			border(CPidx)++;
			border_frequencies(CPidx) = (cdf_value - last_cdf_values(CPidx) )* in.req_proportion(CPidx);
			last_cdf_values(CPidx) = cdf_value;
		end%for

		theta_opt = border .- ones(in.p,1);
	end%else
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
