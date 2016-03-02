% current_cdf_value is the value of the cdf at value current_k. Starting from this data, the function returns
% the value of the cdf at value k. N is the num of objects
function [cdf_value, harmonic_num_returned] = ZipfCDF_smart(k, current_k, current_cdf_value, ...
			alpha, harmonic_num, N)

	global severe_debug;
	max_vec_size = 1e5;
	which_case=0;
	

	if N==0
		if severe_debug; which_case=1; end;
		cdf_value = 0;
		harmonic_num_returned = 0;
	elseif k==0
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

		first_pop = harmonic_num_returned;
		[cdf_value, harmonic_num_returned] = ZipfCDF_smart(k, 1, first_pop, alpha, harmonic_num_returned, N);
	elseif k==current_k
		if severe_debug; which_case=4; end;
		cdf_value = current_cdf_value;
		harmonic_num_returned = harmonic_num;
	elseif k>current_k
		if severe_debug; which_case=5; end;
		p = (current_k+1:k)' .^ alpha;
		p = 1 ./ p;
		cdf_value = current_cdf_value+harmonic_num * sum(p);
		harmonic_num_returned = harmonic_num;
	else %k is not zero and is < current_k
		if current_k-k < k 
			if severe_debug; which_case=6; end;
			p = (k+1:current_k)' .^ alpha;
			p = 1 ./ p;
			cdf_value = current_cdf_value - harmonic_num * sum(p);
			harmonic_num_returned = harmonic_num;
		else
			if severe_debug; which_case=7; end;
			% It is more convenient, in terms of precision, to start computing
			% from the beginning
			p = (1:k)' .^ alpha;
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
