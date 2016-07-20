% Compute the number of misses
% F is a vector whose single cell is the fraction of requests to a single CP

function [num_of_misses_per_CP, tot_requests, F] = compute_num_of_misses_fine(in,...
	current_theta, observation_time)

		global severe_debug;

		if in.know != Inf
			error "This computation is erroneous if popularity knowledge is not perfect"
		end

		num_of_misses_per_CP = requests_per_CP = zeros(in.p, 1);
		for j=1:in.p
			active_obj_indices = find(in.ONobjects(j,:) );
			cached_objs = active_obj_indices(1:current_theta(j) );
			uncached_objs = [];
			if current_theta(j) < length(active_obj_indices)
				uncached_objs = active_obj_indices(...
						current_theta(j)+1: length(active_obj_indices));
			end
			expected_hits  =in.lambda_per_CP(j) * observation_time *...
							in.harmonic_num(j) * sum(1.0 ./(cached_objs.^in.alpha(j) ) );
			expected_misses=0;
			if length(uncached_objs)>0
			expected_misses=in.lambda_per_CP(j) * observation_time *...
							in.harmonic_num(j) * sum(1.0 ./(uncached_objs.^in.alpha(j) ) );
			end
			num_of_misses_per_CP(j,1) = poissrnd(expected_misses);
			num_of_hits_per_CP= poissrnd(expected_hits);
			requests_per_CP(j,1) = num_of_misses_per_CP(j,1)+num_of_hits_per_CP;
		end


		if severe_debug && any( size(requests_per_CP) != [in.p,1] )
			error "dimensions mismatch"
		end

		tot_requests = sum(requests_per_CP);

		if severe_debug && any(num_of_misses_per_CP>repmat(tot_requests,in.p,1) )
			num_of_misses_per_CP
			tot_requests
			error "ciao"
		end
		

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
