% Compute the number of misses
% F is a vector whose single cell is the fraction of requests to a single CP

function [num_of_misses, tot_requests, F] = compute_num_of_misses(settings, epoch, test, in, theta, lambdatau)
		p = in.p;

		rand("seed",settings.seed*epoch*test);randn("seed",settings.seed*epoch*test);
		il_seme_della_discordia = settings.seed*epoch*test
		rand("state",1);randn("state",1);
		vediamolo=random("poisson",10)
		vediamo=poissrnd(10)
		requests = poissrnd(lambdatau); % one row per each CP, one cell per each object
		requests

		max_catalog = max(in.catalog);
		ordinal = repmat(1:max_catalog, p, 1);
		cache_indicator_negated = ordinal > repmat(theta,1,max_catalog);
		num_of_misses = [];
		for j=1:p
			num_of_misses = [num_of_misses; requests(j,:) * cache_indicator_negated(j,:)'];
		end

		tot_requests = sum(sum(requests,2)); % total requests, one cell per each CP


		F = zeros(in.p, 1);
		idx_selector = tot_requests != 0;
		F(tot_requests != 0) = sum(requests,2)(idx_selector) / tot_requests((idx_selector));
end
