% This function is called by build_run.m
%		as_gravity is not used
%		replica_num_distr is not used
function run_ = generate_run(object_reachability_matrix, zipf, as_gravity, total_demand,
						TransitPrice, RealizationProbabilities, experiment)

	global severe_debug;
	% CHECK_INPUT_CONSISTENCY{
	if severe_debug
#		if any(RealizationProbabilities == 0)
#			RealizationProbabilities
#			error("I cannot handle zero RealizationProbablities");
#		end

		if size(TransitPrice) != [length(RealizationProbabilities), length(as_gravity) ]
			error(["length of as_gravity is " length(as_gravity) \
				"while max_as_num is " experiment.max_as_num]);
		end

		if ! my_equality( sum(RealizationProbabilities) , 1.0 )
			RealizationProbabilities
			sum(RealizationProbabilities)
			sum(RealizationProbabilities) - 1
			eq(sum(RealizationProbabilities), 1.0)
			error(["The sum of probabilities is not 1 but ", sum(RealizationProbabilities) ] );
		end

		if length(RealizationProbabilities) != length(RealizationProbabilities)
			scenario_num
			RealizationProbabilities
			error("The number of RealizationProbabilities should be the same as scenario_num");
		end

		if size(object_reachability_matrix,2) != zipf.obj_num
				size(object_reachability_matrix,2)
				zipf.obj_num
				error("Inconsistency in the number of objects");
		endif
	end
	%}

	scenarios = [];
	as_num = length(TransitPrice);
	obj_num = size(object_reachability_matrix, 2);

	for i = 1:length(RealizationProbabilities)
		price = TransitPrice(i,:);
		if RealizationProbabilities(i)>0		
			scenario = generate_scenario( zipf, object_reachability_matrix, total_demand, price);
			scenarios = [scenarios, scenario];
		endif
	endfor

	run_ = merge_scenarios(scenarios);
	run_.RealizationProbabilities = RealizationProbabilities;
	run_.NumASes = as_num;
	run_.NumObjects = obj_num;
	run_.NumScenarios = length(scenarios);
	run_.CachePrice = experiment.CachePrice;
	run_.MaxCachePerBorderRouter = experiment.MaxCachePerBorderRouter;
	run_.MaxCoreCache = experiment.MaxCoreCache;
	run_.MaxTotalCache = experiment.MaxTotalCache;

endfunction
