% Data:
%	k, current_k: cache space
% 	current_cdf_value: the value of the cdf at value current_k. 
%	N: num of objects
% 	estimated_rank: object ids starting from the one that is believed to
%				be the most popular to the others. If the knowledge of the
%				content popularity is perfect, estimated rank is 1,2,...,k
%
% Starting from this data, the function returns the value of the cdf at value k. 
function [cdf_value, harmonic_num_returned] = ZipfCDF_smart(k, current_k, current_cdf_value, ...
			alpha, harmonic_num, N, estimated_rank)

	global severe_debug;
	max_vec_size = 1e5;
	which_case=0;
	
	% cdf value means the expected hit ratio of the cache

	if N==0
		% If the catalog is empty, the cdf value is 0
		if severe_debug; which_case=1; end;
		cdf_value = 0;
		harmonic_num_returned = 0;
	elseif k==0
		% If there is no cache, the cdf is always 0
		if severe_debug; which_case=2; end;
		cdf_value = 0;
		harmonic_num_returned = harmonic_num;
	elseif current_k == 0
		if severe_debug; which_case=3; end;
		% We compute Zipf from the beginning
		partial_sum =0;
		for i=1:max_vec_size:N
			p = (i:min(i+max_vec_size-1, N) )' .^ alpha;
			p = 1./p;
			partial_sum += sum(p);
		end
		harmonic_num_returned = 1/partial_sum;

		% Popularity of the object that is believed to be
		% the most popular
		first_pop = harmonic_num_returned / (estimated_rank(1)^alpha );

		[cdf_value, harmonic_num_returned] = ...
			ZipfCDF_smart(k, 1, first_pop, alpha, harmonic_num_returned, N, estimated_rank);
	elseif k==current_k
		if severe_debug; which_case=4; end;
		cdf_value = current_cdf_value;
		harmonic_num_returned = harmonic_num;
	elseif k>current_k
		if severe_debug; which_case=5; end;
		p = estimated_rank(current_k+1:k)' .^ alpha;
		p = 1 ./ p;
		cdf_value = current_cdf_value+harmonic_num * sum(p);
		harmonic_num_returned = harmonic_num;
	else %k is not zero and is < current_k
		if current_k-k < k 
			if severe_debug; which_case=6; end;
			p = estimated_rank(k+1:current_k)' .^ alpha;
			p = 1 ./ p;
			cdf_value = current_cdf_value - harmonic_num * sum(p);
			harmonic_num_returned = harmonic_num;
		else
			if severe_debug; which_case=7; end;
			% It is more convenient, in terms of precision, to start computing
			% from the beginning
			p = estimated_rank(1:k)' .^ alpha;
			p = 1 ./ p;
			cdf_value = harmonic_num * sum(p);
			harmonic_num_returned = harmonic_num;
		end
	end		


	if severe_debug && isnan(cdf_value) || isinf(cdf_value) || cdf_value<0
		which_case
		cdf_value
		error "cdf_value cannot neither NaN nor infty nor negative"
	end


end


% The following code is to verify
N=5e5+3;
alpha=0.8;
[ pdf, harmonic_num ] = ZipfPDF( alpha, N );

k=1e5+973;
classic_cdf_value = sum(pdf(1:k) )

intermediate_point=3215;
[current_cdf_value, harmonic_num] = ZipfCDF_smart(intermediate_point, 0, [], alpha, [], N);
current_k=intermediate_point;
[cdf_value, harmonic_num_returned] = ZipfCDF_smart(k, current_k, current_cdf_value, ...
			alpha, harmonic_num, N);
new_value = cdf_value
