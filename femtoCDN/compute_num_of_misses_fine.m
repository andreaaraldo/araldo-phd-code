% Compute the number of misses
% F is a vector whose single cell is the fraction of requests to a single CP

function [num_of_misses_per_each_CP, tot_requests, F] = compute_num_of_misses_fine(settings, epoch, test, in, theta, requests_per_object, cache_indicator_negated)

		global severe_debug;
		requests_per_each_CP = sum(requests_per_object,2);

		if severe_debug && any( size(requests_per_each_CP) != [in.p,1] )
			error "dimensions mismatch"
		end

		num_of_misses_per_each_CP = diag(requests_per_object * cache_indicator_negated');

		tot_requests = sum(requests_per_each_CP);
		F = zeros(in.p, 1);
		idx_selector = (requests_per_each_CP != 0);
		F(idx_selector) = requests_per_each_CP(idx_selector) / tot_requests;
end
