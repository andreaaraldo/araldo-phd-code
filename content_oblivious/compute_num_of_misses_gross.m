% Compute the number of misses
% F is a vector whose single cell is the fraction of requests to a single CP

function [nominal_misses, tot_requests, F, cdf, downloads_to_cache] = ...
		compute_num_of_misses_gross(in, current_test_theta, observation_time)

		addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
		global severe_debug;

		if in.ONtime != 1
			error "This computation is erroneous if in.ONtime is not 1"
		end

		if severe_debug
			if any( (in.last_cdf_vector>0) .* (in.last_test_theta==0) )
				last_cdf_vector = in.last_cdf_vector
				last_test_theta = in.last_test_theta
				error "Found a CP which has zero slots but positive cdf (i.e. positive hit ratio). This is an error"
			end
		end

		cdf=zeros(in.p, 1);

		for j=1:in.p
			% estimated_rank(j,:) is a row with the object ids sorted starting from
			% that one that is believed to be the most popular
			estimated_rank = [];
			if in.know < Inf
				% If each CP knows exactly the popularity of its catalog,
				% we do not need the estimated_rank data structure for our computation
				estimated_rank = in.estimated_rank(j,:)';
			end
			[cdf(j,1), harmonic_num_returned] = ZipfCDF_smart(current_test_theta(j), ...
				in.last_test_theta(j),  in.last_cdf_vector(j), in.alpha(j), ...
				in.harmonic_num(j), in.ctlg(j), estimated_rank);
		end

		% in.lambda_per_CP(j,1) is the aggregated rate directed to the CP j
		% cdf(j,1) is the expected hit ratio of CP j
		expected_num_of_hits_per_each_CP = cdf .* in.lambda_per_CP * observation_time ;
		expected_nominal_misses_per_each_CP = ( repmat(1,in.p,1) .- cdf ) .* in.lambda_per_CP * ....
								observation_time ;



		% Using the fact that the sum of poisson variables is a posson variable whose expected value is
		% the sum of the expected values of the summands.
		% The following three column vectors have a cell per each CP
		nominal_misses = poissrnd(expected_nominal_misses_per_each_CP);
		num_of_hits = poissrnd(expected_num_of_hits_per_each_CP);
		requests_per_each_CP = nominal_misses+num_of_hits;

		%{ COMPUTE DOWNLOADS_TO_CACHE
		downloads_to_cache = zeros(in.p,1);
		for j=1:in.p
			for k = in.last_test_theta(j)+1 : current_test_theta(j)
					% estimated_rank: object ids starting from the one that is believed to
					% be the most popular to the others. If the knowledge of the
					% content popularity is perfect, estimated rank is 1,2,...,k
					%
					% We have to download to the cache an object if it was not in the cache before
					% (i.e. it is in some slot in the interval 
					%		[in.last_test_theta(j)+1, current_test_theta(j)]
					% ) and has been requested more than once (whence the use of poissrnd)
					downloads_to_cache(j,1) = downloads_to_cache(j,1) + ...
						(
							poissrnd(in.lambda_per_CP(j) * observation_time * ...
							in.harmonic_num(j) / in.estimated_rank(k)^in.alpha(j) ) > 0
						);
			end %for
		end
		%} COMPUTE DOWNLOADS_TO_CACHE


		tot_requests = sum(requests_per_each_CP); %scalar
		F = zeros(in.p, 1);
		if tot_requests!=0
			F = requests_per_each_CP / tot_requests;
		end

		if severe_debug
			if  any( expected_nominal_misses_per_each_CP < 0)  || ...
				any( expected_num_of_hits_per_each_CP < 0 )

					expected_nominal_misses_per_each_CP
					expected_num_of_hits_per_each_CP
					error("These expected values are erroneous");
			end

			if isnan(tot_requests)
				requests_per_each_CP
				tot_requests
				error("tot_requests is incorrect");
			end

		end
end
