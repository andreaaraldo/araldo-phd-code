% Compute the number of misses
% F is a vector whose single cell is the fraction of requests to a single CP

function [num_of_misses, tot_requests, F, last_cdf_values, last_zipf_points] = compute_num_of_misses_gross(in, ...
				theta, observation_time)

		addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
		global severe_debug;

		requests_per_each_CP = poissrnd( in.lambda_per_CP .* observation_time );
		cdf=zeros(in.p, 1);

		theta_is = theta'
		in_last_zipf_points_is = in.last_zipf_points'
		in_last_cdf_values_is = in.last_cdf_values'
		in_alpha_is = in.alpha'
		in_harmonic_num_is = in.harmonic_num'
		in_ctlg_is = in.ctlg'

		for j=1:in.p			
			[cdf(j,1), harmonic_num_returned] = ZipfCDF_smart(theta(j), in.last_zipf_points(j), ...
				in.last_cdf_values(j), in.alpha(j), in.harmonic_num(j), in.ctlg(j));
		end

		%{ UPDATE LAST CDF VALUES
		last_cdf_values(theta!=0,1) = cdf(theta!=0) ;
		last_zipf_points(theta!=0,1)= theta(theta!=0);
		if severe_debug && ( length(last_cdf_values)!=in.p || length(last_zipf_points)!=in.p)
			last_cdf_values
			last_zipf_points
			error "They should have in.p elements"
		end
		%} UPDATE LAST CDF VALUES


		expected_num_of_misses_per_each_CP = ( repmat(1,in.p,1) .- cdf ) .* in.lambda_per_CP * ....
								observation_time ;
		% Using the fact that the sum of poisson variables is a posson variable whose expected value is
		% the sum of the expected values of the summands 
		num_of_misses = poissrnd(expected_num_of_misses_per_each_CP);

		tot_requests = sum(requests_per_each_CP);
		F = zeros(in.p, 1);
		if tot_requests!=0
			F = requests_per_each_CP / tot_requests;
		end
end
