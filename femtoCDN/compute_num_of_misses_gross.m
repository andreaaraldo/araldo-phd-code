% Compute the number of misses
% F is a vector whose single cell is the fraction of requests to a single CP

function [num_of_misses, tot_requests, F] = compute_num_of_misses_gross(settings, epoch, test, in, theta, lambdatau, cache_indicator_negated)
		p = in.p;

		requests_per_each_CP = poissrnd( sum(lambdatau,2) );

		expected_num_of_misses_per_each_CP = diag(lambdatau * cache_indicator_negated');
		% Using the fact that the sum of poisson variables is a posson variable whose expected value is
		% the sum of the expected values of the summands 
		num_of_misses = poissrnd(expected_num_of_misses_per_each_CP);

		tot_requests = sum(requests_per_each_CP);
		F = zeros(in.p, 1);
		idx_selector = (requests_per_each_CP != 0);
		F(idx_selector) = requests_per_each_CP(idx_selector) / tot_requests;
end
