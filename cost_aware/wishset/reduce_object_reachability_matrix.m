% Called by wishset_algo.m 
% Remove all the not cheapest replicas thus considering only the replicas that are in the cheapest
% possible router. If more than one routers have the minimum price, pick one of them at random
% 		seed is used to control the randomizer generation
function ObjectReachabilityMatrix_reduced = reduce_object_reachability_matrix(
				ObjectReachabilityMatrix, TransitPrice, seed)

	global severe_debug
	rand('seed',seed);

	% {INPUT_CONSISTENCY_CHECK
	if severe_debug
		if length(TransitPrice) != size(ObjectReachabilityMatrix,1)
			disp("length(TransitPrice)=");
			length(TransitPrice)
			disp("size(ObjectReachabilityMatrix,1)");
			size(ObjectReachabilityMatrix,1)
			error("Inconsistent as number");
		end
	end
	% }INPUT_CONSISTENCY_CHECK

	% The rows of ObjectReachabilityMatrix correspond to the different ASes. The columns to the different 
	% objects.

	as_num = length(TransitPrice);
	obj_num = size(ObjectReachabilityMatrix, 2);

	% [sorted_prices, ases_in_price_order] = sort(TransitPrice);

	% The final goal of this script is to sort the object reachability matrix in a price-ascending order and
	% associate each object to the cheapest AS that gives access to it. The procedure is less trivial than
	% it seems. There can be cases in which one object is accessible through more than one AS, all with the
	% same price. We want that, in this case, this script assigns the object randomly to one of them.
	% To do so, we do not order ASes on the base of the TransitPrice but on the base of a FakeTransitPrice.
	% FakeTransitPrice is obtained summing to TransitPrice a random number "randomizer" uniformely
	% distributed in [0,1]. Since randomizer is smaller than 1, the relative order of ASes does not change
	% for any couple of ASes having different TransitPrices, while the relative order can change considering
	% a couple of ASes having the same TransitPrice, that is what we desire.
	randomizer = rand( size(TransitPrice) ) * 0.5;
	FakeTransitPrice = TransitPrice .+ randomizer;
	original_order = 1:as_num;

	

	ObjectReachabilityMatrix_augmented = [ObjectReachabilityMatrix, FakeTransitPrice', original_order'];
	transit_price_column_idx = obj_num+1;
	ObjectReachabilityMatrix_ordered = \
						sortrows( ObjectReachabilityMatrix_augmented, transit_price_column_idx);

	% max(.) returns the "first" index of the maximum value(s) 
	% (https://www.gnu.org/software/octave/doc/interpreter/Utility-Functions.html).
	% For each column of the ObjectReachabilityMatrix_ordered (i.e. for each object) we compute the maximum 
	% value, that we know to be 1, and the first index of the 1-value. This first index corresponds to the
	% cheapest AS.
	% Therefore, index is an array that associates to each object the cheapest AS though which it can be
	% retrieved. This cheapest AS is not identified by its original numbering, but with its position inside
	% ObjectReachabilityMatrix_ordered .
	[value, index] = max(ObjectReachabilityMatrix_ordered,[],1); % 1 means that I'm finding a max for each
																 % each column

	ObjectReachabilityMatrix_reduced = zeros(as_num, obj_num);
	for o=1:obj_num
		% The column obj_num+2 contains the original AS numbering
		as = ObjectReachabilityMatrix_ordered( index(o),  obj_num+2);
		ObjectReachabilityMatrix_reduced(as,o) = 1;
	end

	%%% CONSISTENCY_CHECKS{
		if length(TransitPrice) != size(ObjectReachabilityMatrix,1)
			error("Wrong number of ASes");
		end

		if any(TransitPrice(2:3)<1)
			error( strcat( "randomizer numbers should be smaller than all the TransitPrice. In this case ", 					"this is not guaranteed") );
		end
	%%% }CONSISTENCY_CHECKS
end
