error ("THIS IS AN OLD FILE, I GUESS")

% Hello
%seed = 3;
%rand('seed',seed);

global severe_debug = true;

output_file = "scenario.dat";

% Define an experiment
catalog_size = 10;
cache = catalog_size/1;
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
alpha_distr.array = [1];

as_gravity = [1 1];

total_demand_distr.type = default_distr_type;
total_demand_distr.a = 900000;
total_demand_distr.b = 1000000;

RealizationProbabilities = [1];

scenario_num = length(RealizationProbabilities);
% TransitPrice(i,j) is the price for the j-th AS in the i-th scenario
TransitPrice = zeros(scenario_num, experiment.max_as_num);
TransitPrice = [8,10];

run_ = generate_run(experiment, obj_num_distr, 
					replica_num_distr, alpha_distr, as_gravity, total_demand_distr,
					TransitPrice, scenario_num, RealizationProbabilities);

opl_string = generate_opl_string(run_);

f=fopen(output_file,"w");
fprintf(f,"%s\n",opl_string);
fclose(f);

disp(["The output has been written in " output_file])
