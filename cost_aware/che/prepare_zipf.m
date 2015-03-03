% Modified version of Michele Mangili's code
% N catalog size
% B cache size
function [P_zipf, lambda_obj] = prepare_zipf(N, B, lambda_tot, alpha)

	% Che's Approximation

	% N = input('Insert Content Catalog Cardinality: ');
	% B = input('Insert Cache Size: ');
	% lambda_tot = input('Insert the Aggregated Request Arrival Rate: ');
	% alpha = input('Insert the Zipf Exponent: ');

	% Generation of truncated Zipf distribution

	disp ('welcome')

	P_zipf = zeros(1,N);
	norm_factor = 0;
	for i=1:N
		norm_factor = norm_factor + (1/i^alpha);
	end

	norm_factor = 1 / norm_factor;

	for i=1:N
		P_zipf(1,i) = norm_factor * (1/i^alpha);
	end

	%Calculate the Mean Interarrival Rate per each content

	lambda_obj = zeros(1,N);
	for i=1:N
		lambda_obj(1,i) = P_zipf(1,i) * lambda_tot;
	end
end
