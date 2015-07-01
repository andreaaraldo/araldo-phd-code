% THIS FUNCTION IS OLD AND SHOULD NOT BE CALLED

% scenarios is a list of scenarios
function run_ = merge_scenarios(scenarios)
	global severe_debug;
	error("THIS FUNCTION IS OLD AND SHOULD NOT BE CALLED");
	for i = 1:length(scenarios)
		scenario = scenarios(i);

		% {Check_scenario_consistency
		if size(scenario.object_reachability_matrix,2) != length(scenario.TrafficDemand)
			disp("size(scenario.object_reachability_matrix,2)=")
			size(scenario.object_reachability_matrix,2)
			disp("length(scenario.TrafficDemand)")
			length(scenario.TrafficDemand)
			error("This scenario is malformed");
		end
		% }Check_scenario_consistency

		run_.object_reachability_matrix(:,:,i) = scenario.object_reachability_matrix;
		run_.TransitPrice(i,:) = scenario.TransitPrice;
		run_.TrafficDemand(i,:) = scenario.TrafficDemand;
	end % of for over scenarios

	if severe_debug
		run_.scenarios = scenarios;
	end % of if

end % of function
