% Compute the number of misses
% F is a vector whose single cell is the fraction of requests to a single CP

function [num_of_misses, tot_requests, F, last_cdf_values] = compute_num_of_misses_gross(in, ...
				theta, observation_time)

		addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");

		requests_per_each_CP = poissrnd( in.lambda_per_CP .* observation_time );

		last_cdf_values = zeros(in.p, 1);
		for j=1:in.p
			[cdf_value, harmonic_num_returned] = ZipfCDF_smart(theta, in.last_zipf_points(j), ...
				in.last_cdf_values(j), in.alpha(j), in.harmonic_num(j), []);
			last_cdf_values(j) = cdf_value;
		end


		expected_num_of_misses_per_each_CP = ( repmat(1,in.p,1) .- last_cdf_values ) .* lambda_per_CP * ....
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
