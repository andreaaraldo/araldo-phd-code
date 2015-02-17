% Called by run_numerical_results.m
% 		seed is needed by reduce_object_reachability_matrix
function y = wishset_algo(outputdir, ObjectReachabilityMatrix, TransitPrice, TrafficDemand,
					MaxTotalCache, optimization_dimension, seed)

	global severe_debug;

	disp("\n\nRunning wishset algorithm");

	%%% {INPUT CONSISTENCY CHECKS
	if severe_debug
		if size(TransitPrice,1) != 1
				TransitPrice
				error("I would expect TransitPrice in a different way")
		end

		if size(TrafficDemand,1) != 1
				TrafficDemand
				error("I would expect TrafficDemand in a different way")
		end

		if severe_debug
			if length(TrafficDemand) != size(ObjectReachabilityMatrix,2)
				disp("length(TrafficDemand)=");
				length(TrafficDemand)
				disp("size(ObjectReachabilityMatrix,2)");			
				size(ObjectReachabilityMatrix,2)
				error("Wrong number of objects");
			end

			if length(TransitPrice) != size(ObjectReachabilityMatrix,1)
				error("Wrong number of ASes");
			end

			if !exist(outputdir,'dir')
				error(["directory ", outputdir, " does not exist"]);
			end
		end
	end
	%%% }INPUT CONSISTENCY CHECKS


	obj_num = length(TrafficDemand);
	as_num = length(TransitPrice);

	ObjectReachabilityMatrix = reduce_object_reachability_matrix( \
								ObjectReachabilityMatrix, TransitPrice, seed);

	% objcost(o) will be the cost of retrieval of object
	objprice = TransitPrice * ObjectReachabilityMatrix;
	objcost = objprice .* TrafficDemand;

	weight = [];
	prioritization_factor = 0.01;
	if isequal(optimization_dimension, "cost")
		weight = objcost .+ ( prioritization_factor * ( min(objcost) / max(TrafficDemand) ) ) * TrafficDemand;
	elseif isequal(optimization_dimension, "hitratio")
		weight = TrafficDemand .+ ( prioritization_factor * ( min(TrafficDemand) / max(objcost) ) ) * objcost;
	else
		optimization_dimension
		error_string = ["Optimization dimension ", optimization_dimension, " is not valid"];
		error( error_string );
	endif

	cached_objects = optimize(weight, MaxTotalCache);
	totalgain = sum( objcost(cached_objects) );
	totalcost = sum( objcost ) - totalgain;
	hiratio = sum( TrafficDemand(cached_objects) ) / sum(TrafficDemand);

	%%% Compute cache allocation
		% The greedy algorithm will allocate a cache unit for each cached content. This 
		% cache unit will be placed in the border cache of the cheapest serving AS.
		border_router_cache_sizes = sum(ObjectReachabilityMatrix(:,cached_objects ), 2)';
		core_router_cache_size = 0;
	%%% end

	% Write output
	f=fopen([outputdir,"/","totalcost.csv"],"w");
	fprintf(f,"%s\n",num2str(totalcost) );
	fclose(f);

	f=fopen([outputdir,"/","hitratio.csv"],"w");
	fprintf(f,"%s\n", num2str( hiratio) );
	fclose(f);
	
	f=fopen([outputdir,"/","border_router_cache_sizes.csv"],"w");
	dlmwrite(f, border_router_cache_sizes, ";",0,0);
	fclose(f);

	f=fopen([outputdir,"/","core_router_cache_size.csv"],"w");
	dlmwrite(f, core_router_cache_size, ";",0,0);
	fclose(f);

	disp( [ "Wishset algorithm ended without errors. Output is in ", outputdir ] );
	y=0;
	
endfunction
