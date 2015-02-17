% Return the objects to cache in order to obtain the minimal cost
% weight(o) is thhe cost of retrieval of object o (if optimizing the cost) or 
%    the TtafficDemand (if optimizing the hitratio)
function cached_objects = optimize(weight, MaxTotalCache)
	[sorted_values, ordering] = sort(weight,"descend");
	cached_objects = ordering(1:MaxTotalCache);
end
