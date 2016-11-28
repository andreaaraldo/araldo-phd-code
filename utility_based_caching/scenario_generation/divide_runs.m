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
	for idx_cache_allocation = 1:length(data.cache_allocations)
	for loadd = data.loadds
	for idx_strategy = 1:length(data.strategys)
	for idx_customtype = 1:length(data.customtypes)
	for edge_nodes = data.edge_nodess
	for idx_cache_distribution = 1:length(data.cache_distributions)
	for idx_server_position = 1:length(data.server_positions)
	for idx_user_distribution = 1:length(data.user_distributions)
	for idx_arcs = 1:length(data.arcss)


		%{TOPOLOGY
		cache_distribution = data.cache_distributions{idx_cache_distribution};
		server_position = data.server_positions{idx_server_position};
		user_distribution = data.user_distributions{idx_user_distribution};
		arcs = data.arcss{idx_arcs};
		data.topologys = [];
		command="";
		topology.link_capacity = data.link_capacity;  % In Kbps
		if ( strcmp(data.topofile,"") )
			%{ GENERATE TOPO
			size_ = data.topology_size;
			topology_seed = randint(1,1,range=100,seed)(1,1);
			command = sprintf("%s/scenario_generation/graph_gen/barabasi.r %d %d %g %d",...
					 data.path_base, size_, edge_nodes, data.link_capacity, topology_seed);
			%} GENERATE_TOPO
		else
			% The topology has already been created
			command = sprintf("cat %s/topofiles/%s.net", data.path_base, data.topofile);
		end%if

		[status,topodescription] = system(command);
		%{ CHECK
			if status!=0
				error(sprintf("Error in executing command %s", command) );
			end%if~/software/araldo-phd-code/utility_based_caching/examples/multi_as/gap_0/float/fixed-power4/abilene/cache-constrained/ctlg-100/c2ctlg-0.1/alpha-1/load-2/strategy-RepresentationAware/seed-2/scenario.dat
		%} CHECK

		lines = strsplit(topodescription, del="\n");

		topology.ases = strread(lines{1}, "%d")';

		topology.ASes_with_users = [];
		switch (user_distribution)
			case "edge"
					ASes_with_users_str = strsplit(lines{1}, " ");

					for idx = 1:length(ASes_with_users_str )-1
						topology.ASes_with_users = [topology.ASes_with_users, ...
						str2num( ASes_with_users_str{idx} ) ];
					end %for
			case "specific"
					topology.ASes_with_users = data.ASes_with_users;
			otherwise
					error("user distribution not valid");
		end%switch


		topology.servers = [];
		topology_name = [];

		if ( strcmp(data.topofile,"") )
			% Topology has been generated
			switch (server_position)
				case "edges"
					topology.servers = topology.ASes_with_users;
				case "complement_to_edges"
					topology.servers = setdiff(topology.ases, topology.ASes_with_users);
				case "specific"
					topology.servers = data.servers;
				otherwise
					error("Server position not recognized");
			end %switch

			switch (cache_distribution)
				case "ubiquitous"
					topology.ases_with_storage = 1:size_;
				case "edge"
					topology.ases_with_storage = topology.ASes_with_users;
				case "specific"
					topology.ases_with_storage = data.ases_with_storage;

				otherwise
					error("Unrecognized cache distribution");					
			endswitch
	
			topology.name = sprintf("size_%d-edgenodes_%d-capacity_%g-toposeed_%d-%s", ...
						size_, edge_nodes, topology.link_capacity, topology_seed, ...
						cache_distribution);
		else
			topology.servers = topology.ASes_with_users;
			topology.ases_with_storage = topology.ASes_with_users;
			topology.name = data.topofile;
		end%if

		if (strcmp(arcs,"") )
			% We need to automatically generate arcs
			topology.arcs = lines{2};
		else
			topology.arcs = arcs;
		end

		singledata.topology = topology;
		%}TOPOLOGY


		strategy = data.strategys{idx_strategy};
		singledata.seed = seed;
		singledata.catalog_size = catalog_size;
		singledata.cache_to_ctlg_ratio =  cache_to_ctlg_ratio;
		singledata.alpha = alpha;
		singledata.timelimit = timelimit;
		singledata.solutiongap = solutiongap;
		singledata.fixed_data = fixed_data;
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
	end % arcs
	end % user_distribution
	end % sever_position
	end % cache_distribution
	end % edge_nodes
	end %customtype
	end % startegy
	end % loadd
	end % cache_allocation
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
