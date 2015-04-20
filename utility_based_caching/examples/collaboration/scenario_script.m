%ciao
global severe_debug = true;
path_base = "~/software/araldo-phd-code/utility_based_caching";
addpath(sprintf("%s/scenario_generation",path_base) );
addpath(sprintf("%s/scenario_generation/michele",path_base) );
addpath("~/software/araldo-phd-code/general/process_results" );
addpath("~/software/araldo-phd-code/general/optim_tools" ); % for launch_opl.m
pkg load statistics;


generate = true;
run_ = true;
parallel_processes = 22;

% Define an experiment
experiment_name = "collaboration";

data.topologys = [];
topology.ases = [1, 2, 3];
topology.ases_with_storage = [2,3];
topology.ASes_with_users = [2,3];
topology.server = 1;
for link_capacity = [490000] % In Kbps
	for peer_link_scale = [0.1, 0.5, 0.8, 1, 1.2, 1.5, 2]
		topology.link_capacity = link_capacity;
		topology.arcs = sprintf("{<1, 2, %g>, <1,3, %g>, <2,3,%g>, <3,2,%g> };", ...
			link_capacity, link_capacity, link_capacity*peer_link_scale, link_capacity*peer_link_scale);
			topology.name = sprintf("triangle-%gMbps-peer-%g",link_capacity/1000, peer_link_scale);
			data.topologys = [data.topologys, topology];
	end % peer_link
end % link_capacity

data.seeds = [1];
data.catalog_sizes = [1000];
data.cache_to_ctlg_ratios = [1/100];	% fraction of catalog we could store in the cache if all 
						% the objects were at maximum quality
data.alphas = [1];

fixed_data.path_base = path_base;
fixed_data.rate_per_quality = [0, 300, 700, 1500, 2500, 3500]; % In Kpbs
fixed_data.cache_space_at_low_quality = 11.25;% In MB
fixed_data.utilities = [0, 1, 1.2, 1.3, 1.4, 1.5];
fixed_data.name = "non_linear";
data.fixed_datas = [fixed_data];


data.loadds = [0.1, 1, 2]; 	% Multiple of link capacity we would use to transmit 
				% all the requested objects at low quality

data.strategys = {"RepresentationAware", "NoCache", "AlwaysLowQuality", "AlwaysHighQuality", "AllQualityLevels", "DedicatedCache"};

run_list = divide_runs(experiment_name, data);
for idx_run = 1:length(run_list)
	singledata = run_list(idx_run);
	[singledata.parent_folder, singledata.seed_folder] = folder_names(path_base, experiment_name, singledata);
	error("do not create if it already exists");
	command = sprintf("mkdir -p %s", singledata.seed_folder);
	[status, output] = system(command,1);
	if (status != 0)
		sprintf("%s\n%g\n%s\n",command, status, output);
	end %if
	singledata.dat_filename = sprintf("%s/scenario.dat",singledata.seed_folder);
	generate_opl_dat(singledata);
	run_list(idx_run) = singledata;
end % idx_run

run_scenarios(run_list);

exit(1)
for load_ = loads
	for peer_link_scale = peer_link_scales
		single_value_folders = {};

		##############################
		##### RUN SCENARIOS ##########
		##############################
		active_children = 0;
		if run_
			for seed = seeds
				for idx_single_value = 1:length(single_value_folders)
					single_value_folder = single_value_folders{idx_single_value};
					specific_folder = sprintf("%s/seed_%g", single_value_folder, seed);
					dat_filename = sprintf("%s/scenario.dat",specific_folder);
					mod_filename = sprintf("%s/model.mod",path_base);

					if (active_children > parallel_processes)
						waitpid(-1);
						% One child process finished
						active_children--;
					endif

					pid = fork();
					if (pid==0)
						% I am the child process
						printf("Running experiment %s\n", specific_folder);
						launch_opl(specific_folder, mod_filename, dat_filename);
						exit(0);
					elseif (pid > 0)
						% I am the father
						active_children ++;
					else (pid < 0)
						error ("Error in forking");
					endif
				end % for single_value
			endfor % seed
	
			while (active_children > 0)
				printf("Waiting for %d processes to finish\n", active_children);
				waitpid(-1);
				active_children--;
			end % while
		end % if run_

		##############################
		##### PARSE OUTPUT ###########
		##############################
		printf("Parsing results\n");
		for idx_single_value_folder = 1:length(single_value_folders)
			single_value_folder = single_value_folders{idx_single_value_folder};

			rows_ = 1;
			columns_ = 1;
			utility_header = [];
			utility = zeros(rows_, columns_, length(seeds) );

			rows_ = catalog_size;
			columns_ = 2;
			quality_served_header = [];
			quality_served = zeros(rows_, columns_, length(seeds) );


			rows_ = catalog_size;
			columns_ = 1+length(ases);
			quality_cached_per_rank_header = [];
			quality_cached_per_rank = zeros(rows_, columns_, length(seeds) );



			rows_ = 1;
			columns_ = 1;
			unsatisfied_ratio_header = [];
			unsatisfied_ratio = zeros(rows_, columns_, length(seeds) );


			idx_seed = 0;
			for seed = seeds
					idx_seed ++;
					specific_folder = sprintf("%s/seed_%g", single_value_folder, seed);

					file_to_read = sprintf("%s/objective.csv", specific_folder);
					if (!length(utility_header))
						f = fopen(file_to_read, "r");
						utility_header = fgetl(f);
						fclose(f);
					endif
					value = dlmread(file_to_read,' ',1,0);
					utility(:,:,idx_seed)  = value;
					file_to_read = sprintf("%s/quality_served_per_rank.csv",  specific_folder);
					if (!length(quality_served_header))
						f = fopen(file_to_read, "r");
						quality_served_header = fgetl(f);
						fclose(f);
					endif
					value = dlmread(file_to_read,' ',1, 0);
					quality_served(:,:,idx_seed) = value;


					file_to_read = sprintf("%s/quality_cached_per_rank.csv",  specific_folder);
					if (!length(quality_cached_per_rank_header))
						f = fopen(file_to_read, "r");
						quality_cached_per_rank_header = fgetl(f);
						fclose(f);
					endif
					value = dlmread(file_to_read,' ',1, 0);
					quality_cached_per_rank(:,:,idx_seed) = value;



					file_to_read = sprintf("%s/unsatisfied_ratio.csv",  specific_folder);
					if (!length(unsatisfied_ratio_header) )
						f = fopen(file_to_read, "r");
						unsatisfied_ratio_header = fgetl(f);
						fclose(f);
					endif
					value = dlmread(file_to_read,' ',1,0);
					unsatisfied_ratio(:,:,idx_seed)  = value;
			endfor % seed

			%{ CHECK
	
			if (size(utility,3)!=length(seeds) || size(quality_served,3)!=length(seeds) || ...
				size(quality_cached_per_rank,3)!=length(seeds) || size(unsatisfied_ratio,3)!=length(seeds) )
				error("ERROR: bad matrix size");
			end % if
			%} CHECK

			##############################
			##### PROCESS OUTPUT #########
			##############################
			dim_to_reduce = 3;

			for seed = seeds
					file_to_write = sprintf("%s/utility.dat",single_value_folder);
					utility_mean = nanmean(utility, dim_to_reduce);
					utility_confidence = confidence_interval(utility, dim_to_reduce, ignore_NaN=true);
					f = fopen(file_to_write, "w+");
					fprintf(f, "#%s %s\n",utility_header, utility_header );
					fclose(f);
					dlmwrite(file_to_write,[utility_mean, utility_confidence], 
							"append","on", "delimiter"," ");
			

					file_to_write = sprintf("%s/quality_served.dat",single_value_folder);
					quality_served_mean = nanmean(quality_served, dim_to_reduce);
					quality_served_confidence = confidence_interval(quality_served, 
							dim_to_reduce, ignore_NaN=true);
					f = fopen(file_to_write, "w+");
					fprintf(f, "#%s %s\n",quality_served_header, quality_served_header );
					fclose(f);
					dlmwrite(file_to_write,[quality_served_mean, quality_served_confidence],
							"append","on", "delimiter"," ");



					file_to_write = sprintf("%s/quality_cached_per_rank.dat",single_value_folder);
					quality_cached_per_rank_mean = nanmean(quality_cached_per_rank, dim_to_reduce);
					quality_cached_per_rank_confidence = confidence_interval(quality_cached_per_rank, 
							dim_to_reduce, ignore_NaN=true);
					f = fopen(file_to_write, "w+");
					fprintf(f, "#%s %s\n",quality_cached_per_rank_header, quality_cached_per_rank_header );
					fclose(f);
					dlmwrite(file_to_write,[quality_cached_per_rank_mean, quality_cached_per_rank_confidence],
							"append","on", "delimiter"," ");


					file_to_write = sprintf("%s/unsatisfied_ratio.dat", single_value_folder);
					unsatisfied_ratio_mean = nanmean(unsatisfied_ratio, dim_to_reduce);
					unsatisfied_ratio_confidence = confidence_interval(
											unsatisfied_ratio, dim_to_reduce, ignore_NaN=true);
					f = fopen(file_to_write, "w+");
					fprintf(f, "#%s %s\n",unsatisfied_ratio_header, unsatisfied_ratio_header );
					fclose(f);
					dlmwrite(file_to_write,[unsatisfied_ratio_mean, unsatisfied_ratio_confidence], 
							"append","on", "delimiter"," ");

			endfor % seed
		endfor %idx_single_value_folder
	end % for peer_link_scale
end % for load
