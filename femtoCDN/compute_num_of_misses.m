% Compute the number of misses
% y is the miss intensity
function [num_of_misses, tot_requests] = compute_num_of_misses(in, theta, lambdatau)
		p = length(theta);

		requests = poissrnd(lambdatau); % one row per each CP, one cell per each object

		max_catalog = max(in.catalog);
		ordinal = repmat(1:max_catalog, p, 1);
		cache_indicator_negated = ordinal > repmat(theta,1,max_catalog);
		num_of_misses = [];
		for j=1:p
			num_of_misses = [num_of_misses; requests(j,:) * cache_indicator_negated(j,:)'];
		end

		tot_requests = sum(sum(requests) ); % total requests, one cell per each CP
end
