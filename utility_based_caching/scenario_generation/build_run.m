% If output_file is not "", a file cplex-compliant will be generated. This file can be used as input to oplrun.
function run_ = build_run(output_file, catalog_size, max_cache, price_ratio, seed_, totaldemand, alpha)


	error("THIS FUNCTION IS OLD. It is very strange you are calling it");
	% price_ratio: if set to a negative number, number of border routers, their prices and scenarios will be that are hardcoded here. If price_ratio is some positive number, there will be only one scenario and the prices are set depending on this ratio 
	rand('seed',seed_);

	global severe_debug = true;

	% Define an experiment
	cache = max_cache;
	experiment.CachePrice = 0;
	experiment.MaxCoreCache = cache;
	experiment.MaxCachePerBorderRouter = cache;
	experiment.MaxTotalCache = cache;
	experiment.max_as_num = 2;
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

	as_gravity = [1 1];

	total_demand_distr.type = default_distr_type;
	total_demand_distr.a = totaldemand;
	total_demand_distr.b = totaldemand;

	if price_ratio > 0
		RealizationProbabilities = [1, 0];
		scenario_num = length(RealizationProbabilities);
		% TransitPrice(i,j) is the price for the j-th AS in the i-th scenario
		TransitPrice = [1,price_ratio; 0,0;];
	else
		RealizationProbabilities = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1];
		scenario_num = length(RealizationProbabilities);
		% TransitPrice(i,j) is the price for the j-th AS in the i-th scenario
		TransitPrice = zeros(scenario_num, experiment.max_as_num);
		TransitPrice = [8,10; 1,0; 100,2100; 800000,0; 5,5; 6,6; 1000000,20; 88,7; 5,9000; 100000,100000];
	end


	obj_num = sample(obj_num_distr);
	alpha = sample(alpha_distr);
	total_demand = sample(total_demand_distr);

	object_reachability_matrix = generate_object_reachability_matrix(as_num, obj_num);
	zipf = generate_zipf(alpha, obj_num);


	run_ = generate_run(object_reachability_matrix, zipf, as_gravity, total_demand,
						TransitPrice, scenario_num, RealizationProbabilities);

	if !isequal(output_file,"")
		disp("Generating oplfile at time ");
		clock()
		 generate_opl_file(run_, output_file);

		disp(["The output has been written in ",output_file," at time"])
		clock()
	end
	disp("Run built without errors");
end
