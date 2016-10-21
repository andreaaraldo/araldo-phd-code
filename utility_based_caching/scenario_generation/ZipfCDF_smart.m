% Data:
%	k, current_k: cache space
% 	current_cdf_value: the value of the cdf at value current_k. Note that
%				the cdf corresponds to the hit ratio.
%	N: num of objects
% 	estimated_rank: object ids starting from the one that is believed to
%				be the most popular to the others. If the knowledge of the
%				content popularity is perfect, estimated rank is [].
%
% Starting from these data, the function returns the value of the cdf at value k. 
function [cdf_value, harmonic_num_returned] = ZipfCDF_smart(k, current_k, current_cdf_value, ...
			alpha, harmonic_num, N, estimated_rank)

	global severe_debug;
	max_vec_size = 1e5;
	which_case=0;

	if severe_debug
		if current_k == 0 && current_cdf_value > 0
			current_cdf_value
			error "the current_cdf value cannot be positive if no slots are currently allocated"
		end
	end
	
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
	elseif length(harmonic_num) == 0
		if severe_debug; which_case=3; end;
		% The harmonic number has not yet been computed.
		% We compute Zipf from the beginning
		% First, we try to lookup for an already computed harmonic number
		harmonic_num_returned = harmonic_num_lookup(N,alpha);
		if length(harmonic_num_returned)==0
			% There is no value of harmonic num pre-computed. We have to compute it.
			partial_sum =0;
			for i=1:max_vec_size:N
				p = (i:min(i+max_vec_size-1, N) )' .^ alpha;
				p = 1./p;
				partial_sum += sum(p);
			end
			harmonic_num_returned = 1/partial_sum;
		end

		% Popularity of the object that is believed to be
		% the most popular
		first_pop = harmonic_num_returned;
		% If popularity knowledge is perfect, first_pop is already computed above. 
		% Otherwise ....
		if length(estimated_rank)>0
			first_pop = harmonic_num_returned / (estimated_rank(1)^alpha );
		end

		[cdf_value, harmonic_num_returned] = ...
			ZipfCDF_smart(k, 1, first_pop, alpha, harmonic_num_returned, N, estimated_rank);
	elseif k==current_k
		if severe_debug; which_case=4; end;
		cdf_value = current_cdf_value;
		harmonic_num_returned = harmonic_num;
	elseif k>current_k
		if severe_debug; which_case=5; end;
		if current_k+1 > N
			% Adding other slots to the current_k is not giving 
			% additional benefit, since with current_k we already
			% cover all the N objects in the catalog
			cdf_value = current_cdf_value;
		else
			objs_to_consider = current_k+1:min(k,N);
			if length(estimated_rank)>0
				% Knowledge is imperfect
				objs_to_consider = estimated_rank(current_k+1:min(k,N) );
			end
			p = objs_to_consider' .^ alpha;
			p = 1 ./ p;
			cdf_value = current_cdf_value+harmonic_num * sum(p);
		end
		harmonic_num_returned = harmonic_num;
	else %k is not zero and is < current_k
		if current_k-k < k 
			if severe_debug; which_case=6; end;

			objs_to_consider = k+1:current_k;
			if length(estimated_rank)>0
				% Knowledge is imperfect
				objs_to_consider = estimated_rank(k+1:current_k );
			end
			p = objs_to_consider' .^ alpha;
			p = 1 ./ p;
			cdf_value = current_cdf_value - harmonic_num * sum(p);
			harmonic_num_returned = harmonic_num;

		else
			if severe_debug; which_case=7; end;
			% It is more convenient, in terms of precision, to start computing
			% from the beginning

			objs_to_consider = 1:k;
			if length(estimated_rank)>0
				% Knowledge is imperfect
				objs_to_consider = estimated_rank(1:k );
			end
			p = objs_to_consider' .^ alpha;
			p = 1 ./ p;
			cdf_value = harmonic_num * sum(p);
			harmonic_num_returned = harmonic_num;
		end
	end		

	% Due to precision issues in float computation, the cdf could be slightly 
	% greater than 1. In this case, we adjust the value to 1.
	if cdf_value > 1 && cdf_value < 1+1e-10
		cdf_value = 1;
	end


	if severe_debug
		if cdf_value > 0 && k==0
			cdf_value
			error "cdf cannot be positive if slots are 0"
		end

		if isnan(cdf_value) || isinf(cdf_value) || cdf_value<0
			which_case
			cdf_value
			error "cdf_value cannot neither NaN nor infty nor negative"
		end

		if cdf_value < 0 || cdf_value > 1
			which_case
			cdf_value

			%{ CHECK THE HARMONIC NUMBER
			p = estimated_rank(1:N)' .^ alpha;
			p = 1 ./ p;
			the_sum = sum(p);
			if abs(the_sum * harmonic_num - 1)>1e-10
				the_sum
				harmonic_num
				product = the_sum* harmonic_num
				error "The harmonic number is erroneous"
			end
			%} CHECK THE HARMONIC NUMBER

			p = (1:N )' .^ alpha;
			p = harmonic_num ./p;
			popularities = p'
			length_=length(p)
			current_k
			k
			additional_vector = p(current_k+1:k) '
			contribute_of_the_additional = sum(additional_vector)
			current_cdf_value
			error("A cdf cannot be neither negative nor greater than 1");
		end
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
