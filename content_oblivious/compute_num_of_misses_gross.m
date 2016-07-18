% Compute the number of misses
% F is a vector whose single cell is the fraction of requests to a single CP

function [num_of_misses, tot_requests, F, last_cdf_values_returned, last_zipf_points_returned] =...
				 compute_num_of_misses_gross(in, theta, observation_time)

		addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
		global severe_debug;

		cdf=zeros(in.p, 1);

		for j=1:in.p
			% estimated_rank(j,:) is a row with the object ids sorted starting from
			% that one that is believed to be the most popular
			in.estimated_rank = in.estimated_rank(j,:)';
			[cdf(j,1), harmonic_num_returned] = ZipfCDF_smart(theta(j), in.last_zipf_points(j), ...
				in.last_cdf_values(j), in.alpha(j), in.harmonic_num(j), in.ctlg(j), ...
				estimated_rank);
		end

		%{ UPDATE LAST CDF VALUES
		last_cdf_values_returned = in.last_cdf_values;
		last_zipf_points_returned= in.last_zipf_points;
		last_cdf_values_returned(theta!=0,1) = cdf(theta!=0) ;
		last_zipf_points_returned(theta!=0,1)= theta(theta!=0);
		if severe_debug && ( length(last_cdf_values_returned)!=in.p || length(last_zipf_points_returned)!=in.p)
			cdf_selected = cdf(theta!=0)
			theta_selected = theta(theta!=0)
			theta!=0
			last_cdf_values_returned
			last_zipf_points_returned
			error "They should have in.p elements"
		end
		%} UPDATE LAST CDF VALUES


		expected_num_of_misses_per_each_CP = ( repmat(1,in.p,1) .- cdf ) .* in.lambda_per_CP * ....
								observation_time ;
		expected_num_of_hits_per_each_CP = cdf .* in.lambda_per_CP * observation_time ;



		% Using the fact that the sum of poisson variables is a posson variable whose expected value is
		% the sum of the expected values of the summands 
		num_of_misses = poissrnd(expected_num_of_misses_per_each_CP);
		num_of_hits = poissrnd(expected_num_of_hits_per_each_CP);
		requests_per_each_CP = num_of_misses+num_of_hits;


		tot_requests = sum(requests_per_each_CP);
		F = zeros(in.p, 1);
		if tot_requests!=0
			F = requests_per_each_CP / tot_requests;
		end
end
