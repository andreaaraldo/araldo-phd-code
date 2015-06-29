%ciao
function run_list = divide_runs(experiment_name, data)
	run_list = [];
	for seed = data.seeds
	for catalog_size = data.catalog_sizes
	for cache_to_ctlg_ratio =  data.cache_to_ctlg_ratios
	for alpha = data.alphas
	for timelimit = data.timelimits
	for solutiongap = data.solutiongaps
	for fixed_data = data.fixed_datas
	for topology = data.topologys
	for idx_cache_allocation = 1:length(data.cache_allocations)
	for loadd = data.loadds
	for idx_strategy = 1:length(data.strategys)
	for idx_customtype = 1:length(data.customtypes)
		strategy = data.strategys{idx_strategy};
		singledata.seed = seed;
		singledata.catalog_size = catalog_size;
		singledata.cache_to_ctlg_ratio =  cache_to_ctlg_ratio;
		singledata.alpha = alpha;
		singledata.timelimit = timelimit;
		singledata.solutiongap = solutiongap;
		singledata.fixed_data = fixed_data;
		singledata.topology = topology;
		singledata.cache_allocation = data.cache_allocations{idx_cache_allocation};
		singledata.loadd = loadd;
		singledata.strategy = strategy;
		singledata.customtype = data.customtypes{idx_customtype};
		[singledata.parent_folder, singledata.seed_folder, singledata.request_file] = ...
			folder_names(fixed_data.path_base, experiment_name, singledata);
		singledata.dat_filename = sprintf("%s/scenario.dat",singledata.seed_folder);
		singledata.mod_filename = sprintf("%s/model.mod",singledata.seed_folder);
		
		run_list = [run_list, singledata];


		%{CHECK
		admissible_strategies = {"RepresentationAware", "NoCache", "AlwaysLowQuality", "AlwaysHighQuality",...
					 "AllQualityLevels", "DedicatedCache", "ProportionalDedicatedCache"};
		if ( !strcmp(singledata.strategy,"RepresentationAware") && !strcmp(singledata.strategy,"NoCache") && ...
			 !strcmp(singledata.strategy,"AlwaysLowQuality") && ...
			 !strcmp(singledata.strategy,"AlwaysHighQuality") && !strcmp(singledata.strategy,"AllQualityLevels")...
			 && !strcmp(singledata.strategy,"DedicatedCache") && !strcmp(singledata.strategy,"PropDedCache") )
			
			error(sprintf("ERROR: strategy %s is not valid", singledata.strategy) );
		end %if
		%}CHECK
	end %customtype
	end % startegy
	end % loadd
	end % cache_allocation
	end % topology
	end % fixed_data
	end % solutiongap
	end % timelimit
	end % alpha
	end % cache_to_ctlg_ratio
	end % catalog_size
	end %seed
%	run_list
%	for idx_list = length(run_list)
%		run_list(idx_list)
%	end
end % function
