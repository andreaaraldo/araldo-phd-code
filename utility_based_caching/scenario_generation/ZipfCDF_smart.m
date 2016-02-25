% current_cdf_value is the value of the cdf at value current_k. Starting from this data, the function returns
% the value of the cdf at value k. N is the num of objects
function [cdf_value, harmonic_num_returned] = ZipfCDF_smart(k, current_k, current_cdf_value, ...
			alpha, harmonic_num, N)

	harmonic_num_returned = harmonic_num;
	if current_k == 0
		% We compute the cdf from the beginning
		[pdf, harmonic_num_returned] = ZipfPDF(alpha, N);
		cdf_value = sum(pdf(1:k) );
	elseif k==current_k
		cdf_value = current_cdf_value;
	elseif k>current_k
		p = (current_k+1:k)' .^ alpha;
		p = 1 ./ p;
		cdf_value = current_cdf_value+harmonic_num * sum(p);
		
	else
		p = (k:current_k)' .^ alpha;
		p = 1 ./ p;
		cdf_value = current_cdf_value - harmonic_num * sum(p);
	end		
end


% The following code is to verify
N=6547899;
alpha=0.8;
[ pdf, harmonic_num ] = ZipfPDF( alpha, N );

k=549684;
classic_cdf_value = sum(pdf(1:k) )

intermediate_point=5496845;
[current_cdf_value, harmonic_num] = ZipfCDF_smart(intermediate_point, 0, [], alpha, [], N);
current_k=intermediate_point;
[cdf_value, harmonic_num_returned] = ZipfCDF_smart(k, current_k, current_cdf_value, ...
			alpha, harmonic_num, N);
new_value = cdf_value
