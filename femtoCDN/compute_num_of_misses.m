% Compute the number of misses
% F is a vector whose single cell is the fraction of requests to a single CP

function [num_of_misses, tot_requests, F] = compute_num_of_misses(in, theta, lambdatau)
		p = in.p;

		requests = poissrnd(lambdatau); % one row per each CP, one cell per each object

		max_catalog = max(in.catalog);
		ordinal = repmat(1:max_catalog, p, 1);
		cache_indicator_negated = ordinal > repmat(theta,1,max_catalog);
		num_of_misses = [];
		for j=1:p
			num_of_misses = [num_of_misses; requests(j,:) * cache_indicator_negated(j,:)'];
		end

		F = sum(requests,2)
		error("ciao");
		tot_requests = sum(sum(requests) ); % total requests, one cell per each CP
		num_of_misses(theta < 0) = -theta(theta < 0) * tot_requests;
end
