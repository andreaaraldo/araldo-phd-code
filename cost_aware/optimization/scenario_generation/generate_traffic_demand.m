% Generate a demand for each object, i.e. a number of requests for the object.
% This function is called by run_numerical_results
%		zipf is an object generated via generate_zipf.m
%		
function traffic_demand = generate_traffic_demand(zipf, total_demand)
	global severe_debug;
	% {INPUT CHECK
	if severe_debug
		if size(zipf.distr,1) != 1
				zipf.distr
				error("I would expect zipf.distr in a different way")
		end
	end
	% }INPUT_CHECK

	% rank_matrix = sparse( eye (zipf.obj_num) );
	traffic_demand = round( zipf.distr .* total_demand );

	% {OUTPUT CHECK
	if severe_debug
		if size(traffic_demand,1) != 1
				traffic_demand
				error("I would expect traffic_demand in a different way")
		end
	end
	% }OUTPUT_CHECK

endfunction
