%
function [miss, tot_requests] = compute_miss(in, c, lambdatau)
		N = length(c);

		%{REQUEST GENERATION
		requests = [];
		max_catalog = max(in.catalog);
		for j=1:N
			these_requests = zeros(1,max_catalog);
			these_requests(1:in.catalog(j) ) = poissrnd(lambdatau(j,:) );
			requests = [requests; these_requests ];
		end%for
		%}REQUEST GENERATION

		ordinal = repmat(1:max_catalog, N, 1);
		cache_indicator_negated = ordinal > repmat(c,1,max_catalog);
		m = [];
		for j=1:N
			m = [m; requests(j,:) * cache_indicator_negated(j,:)'];
		end

		f = sum(requests, 2 ); % total requests

		miss = m;
		tot_requests = f;
end
