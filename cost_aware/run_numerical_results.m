% ciao

output_folder="~/shared_with_servers/icn14_runs/greedy_algo";


starting_time = time();
global severe_debug = true;

addpath("wishset");
addpath("optimization");
addpath("optimization/scenario_generation");

scenario_num = 1;  % How many scenarios you want inside your stochastic optimization
RealizationProbabilities = [1];
as_probability = [0.333 0.333 0.334]; % peering link, cheap link, expensive link
as_num = length(as_probability);
replication_admitted = false;


catalog_size_list = [1e4, 1e5, 1e6, 1e7, 1e8];
cache_size_list = [0,1e3];
seed_list = 1:20;
alpha_list = [1];
total_demand_list = [180000];
price_ratio_list = [10];
optimization_goal_list = {"cost"}; # it can be "cost" or "hitratio"

for catalog_size = catalog_size_list
	for alpha = alpha_list
		zipf = []; % Generate zipf only if it is really needed
		for seed = seed_list
			rand('seed',seed);
			object_reachability_matrix = []; % Generate it only if it is really needed

			% {Strange_check
			if severe_debug
				if !isempty(object_reachability_matrix)
					error("isempty is used in an improper way");
				end
			end
			% }Strange_check

			for total_demand = total_demand_list
				for total_demand = total_demand_list				

					traffic_demand = [];
					for price_ratio = price_ratio_list

						TransitPrice = [0, 1, price_ratio];

						for cache_size = cache_size_list

							for optimization_goal_idx = 1:length(optimization_goal_list)
								optimization_goal = optimization_goal_list{optimization_goal_idx};

								total_demand = 1800*100*catalog_size/100000;

								run_name = [output_folder,"/wishset-model_ideal-",optimization_goal,"-ctlg_",\
									num2str(catalog_size),\
									"-cache_",num2str(cache_size),\
									"-priceratio_",num2str(price_ratio),"-seed_",num2str(seed),\
									"-totaldemand_",num2str(total_demand),\
									"-alpha_",num2str(alpha),"-asprob_",num2str(as_probability(1)),"_", \
									num2str(as_probability(2)),"_", num2str(as_probability(3))];

								if !exist(run_name,'dir')
									if isempty(zipf)
										% This is the first time I need a zipf with these values of alpha and 
										% catalog_size
										% So I need to compute the zipf
										zipf = generate_zipf(alpha, catalog_size);
									%else
										% zipf with the proper values of alpha and catalog_size was already computed
										% and it is ready to be used. Do not recompute it again.
									end

									% Here, reason as in the zipf case
									if isempty(object_reachability_matrix)
										[object_reachability_matrix, replication] =\
												 generate_object_reachability_matrix(\
															catalog_size, as_probability,replication_admitted);
									end

									% {CONSISTENCY_CHECK
									if severe_debug
										if size(object_reachability_matrix,2) != catalog_size
												size(object_reachability_matrix,2)
												catalog_size
												error("Wrong obj num in object_reachability_matrix");
										endif

										if catalog_size != zipf.obj_num
												catalog_size
												disp("zipf.obj_num=");
												zipf.obj_num
												error("The number of objects in the zipf is not correct");
										endif

										if size(object_reachability_matrix,2) != zipf.obj_num
												size(object_reachability_matrix,2)
												zipf.obj_num
												error("Inconsistency in the number of objects");
										endif
									end
									% }CONSISTENCY_CHECK

									% Here, reason as in the zipf case
									if isempty(traffic_demand)
										traffic_demand = generate_traffic_demand(zipf, total_demand);
									end
					
									[status, msg, msgid] = mkdir( run_name );
									% {CHECK
									if severe_debug && status != 1
										run_name
										msg
										msgid
										error("Error in creating folder");
									end
									% }CHECK

									if size(traffic_demand,1) != 1
											traffic_demand
											error("I would expect traffic_demand in a different way")
									end

									time1 = time();
									%save "~/temp/workspace.dat"
									y = wishset_algo ( run_name , object_reachability_matrix, \
													TransitPrice, \
													traffic_demand,\
													cache_size, optimization_goal, seed);
									execution_time = time() - time1;
									
									dlmwrite([run_name,"/execution_time.csv"], execution_time);
									replication_file = [run_name,"/","replication.csv"];
									f=fopen(replication_file,"w");
									fprintf(f,"%s\n","ratio of objects that are replicated 1,2,3,... times" );
									fclose(f);
									dlmwrite(replication_file, replication, "-append");
								else
									disp(["\n\nThe run ", run_name, \
												" has already been executed. I am not going to do it again"]);
								end


							end
						end
					end
				end
			end
		end
	end
end

disp("total execution time")
time() - starting_time
