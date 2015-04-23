%ciao
function run_list = divide_runs(experiment_name, data)
	run_list = [];
	for seed = data.seeds
	for catalog_size = data.catalog_sizes
	for cache_to_ctlg_ratio =  data.cache_to_ctlg_ratios
	for alpha = data.alphas
	for fixed_data = data.fixed_datas
	for topology = data.topologys
	for loadd = data.loadds
	for idx_strategy = 1:length(data.strategys)
		strategy = data.strategys{idx_strategy};
		singledata.seed = seed;
		singledata.catalog_size = catalog_size;
		singledata.cache_to_ctlg_ratio =  cache_to_ctlg_ratio;
		singledata.alpha = alpha;
		singledata.fixed_data = fixed_data;
		singledata.topology = topology;
		singledata.loadd = loadd;
		singledata.strategy = strategy;
		[singledata.parent_folder, singledata.seed_folder, singledata.request_file] = ...
			folder_names(fixed_data.path_base, experiment_name, singledata);
		singledata.dat_filename = sprintf("%s/scenario.dat",singledata.seed_folder);
		
		run_list = [run_list, singledata];
	end % startegy
	end % loadd
	end % topology
	end % fixed_data
	end % alpha
	end % cache_to_ctlg_ratio
	end % catalog_size
	end %seed
%	run_list
%	for idx_list = length(run_list)
%		run_list(idx_list)
%	end
end % function
