% If output_file is not "", a file cplex-compliant will be generated. This file can be used as input to oplrun.
function build_run(output_file, catalog_size, max_cache, price_ratio, seed_, totaldemand, alpha)

	% price_ratio: if set to a negative number, number of border routers, their prices and scenarios will be that are hardcoded here. If price_ratio is some positive number, there will be only one scenario and the prices are set depending on this ratio 
	rand('seed',seed_);

	global severe_debug = true;

	% Define an experiment
	cache = max_cache;
	experiment.CachePrice = 0;
	experiment.MaxCoreCache = cache;
	experiment.MaxCachePerBorderRouter = cache;
	experiment.MaxTotalCache = cache;
	experiment.max_obj_num = catalog_size;

	% Define the distributions
	default_distr_type = "unif_discr";

	obj_num_distr.type = default_distr_type;
	obj_num_distr.a = experiment.max_obj_num;
	obj_num_distr.b = experiment.max_obj_num;

	replica_num_distr.type = default_distr_type;
	replica_num_distr.a = 1;
	replica_num_distr.b = 2;

	alpha_distr.type = "unif_array";
	alpha_distr.array = [alpha];

	as_probability = [1 1 1]; % as_probability[i] is the probability that a generic object
							% is reachable through as i.

	total_demand_distr.type = default_distr_type;
	total_demand_distr.a = totaldemand;
	total_demand_distr.b = totaldemand;

	if price_ratio > 0
		RealizationProbabilities = [1, 0];
		% TransitPrice(i,j) is the price for the j-th AS in the i-th scenario
		TransitPrice = [0, 1,price_ratio; 0, 0,0;];
	else
		error("Price ratio must be > 0");
	end


	obj_num = sample(obj_num_distr);
	alpha = sample(alpha_distr);
	total_demand = sample(total_demand_distr);

	object_reachability_matrix = generate_object_reachability_matrix(obj_num, as_probability,\
								 replication_admitted=true);
	zipf = generate_zipf(alpha, obj_num);

	run_ = generate_run(object_reachability_matrix, zipf, as_probability, total_demand,
						TransitPrice, RealizationProbabilities, experiment);


	if !isequal(output_file,"")
		generate_opl_file(run_, output_file);
	end
end
