% Compute the number of misses
% F is a vector whose single cell is the fraction of requests to a single CP

function [num_of_misses_per_CP, tot_requests, F] = compute_num_of_misses_fine(in, current_theta,...
	observation_time)

		global severe_debug;

		num_of_misses_per_CP = requests_per_CP = zeros(in.p, 1);
		for j=1:in.p
			active_obj_indices = find(in.ONobjects(j,:) );
			cached_objs = active_obj_indices(1:current_theta(j) );
			hit_prob = in.harmonic_num(j)./(cached_objs.^in.alpha(j) );
			miss_prob = 1-hit_prob;
			expected_num_of_misses = miss_prob * in.lambda_per_CP(j) * observation_time;
			num_of_misses_per_CP(j) = poissrnd(expected_num_of_misses);
			requests_per_CP(j) = poissrnd(in.lambda_per_CP(j));
		end


		if severe_debug && any( size(requests_per_CP) != [in.p,1] )
			error "dimensions mismatch"
		end

		tot_requests = sum(requests_per_CP);
		F = zeros(in.p, 1);
		if tot_requests!=0
			F = requests_per_CP / tot_requests;
		end
end


function [num_of_misses_per_each_CP, tot_requests, F] = compute_num_of_misses_fine_old (settings, epoch, test, in, theta, requests_per_object, cache_indicator_negated)

		global severe_debug;
		requests_per_each_CP = sum(requests_per_object,2);

		if severe_debug && any( size(requests_per_each_CP) != [in.p,1] )
			error "dimensions mismatch"
		end

		num_of_misses_per_each_CP = diag(requests_per_object * cache_indicator_negated');

		tot_requests = sum(requests_per_each_CP);
		F = zeros(in.p, 1);
		if tot_requests!=0
			F = requests_per_each_CP / tot_requests;
		end
end
