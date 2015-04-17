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
seeds = 1;
ases = [1, 2, 3];
ases_with_storage = [2,3];
catalog_size = 1000;
cache_to_ctlg_ratio = 1/100;	% fraction of catalog we could store in the cache if all 
						% the objects were at maximum quality
alpha = 1;

rate_per_quality = [0, 300, 700, 1500, 2500, 3500]; % In Kpbs

cache_space_at_low_quality = 11.25;% In MB

utilities = [0, 1, 1.2, 1.3, 1.4, 1.5];

ASes_with_users = [2,3];
server = 1;
link_capacity = 490000; % In Kbps

peer_link_scales = [0.1, 0.5, 0.8, 1, 1.2, 1.5, 2];
loads = [0.1, 1, 2]; 	% Multiple of link capacity we would use to transmit 
				% all the requested objects at low quality

strategies = {"RepresentationAware", "NoCache", "AlwaysLowQuality", "AlwaysHighQuality", "AllQualityLevels", "DedicatedCache"};

for load_ = loads
	for peer_link_scale = peer_link_scales
		single_value_folders = {};

		##############################
		##### GENERATE SCENARIOS #####
		##############################
		for strategy_idx = 0:( length(strategies)-1 )
			strategy = strategies{strategy_idx+1};
			total_requests = load_ * length(ASes_with_users) * link_capacity / rate_per_quality(2);
			arcs = sprintf("{<1, 2, %g>, <1,3, %g>, <2,3,%g>, <3,2,%g> };", ...
				link_capacity, link_capacity, link_capacity*peer_link_scale, link_capacity*peer_link_scale);

			quality_level_num = length(rate_per_quality)-1; % number of qualities starting from q=1

			% {BUILD CACHE_SPACE_PER_QUALITY
			cache_space_per_quality = [10000];
			for idx_q = 2:quality_level_num+1
				cache_space_per_quality = [cache_space_per_quality, ...
					cache_space_at_low_quality * rate_per_quality(idx_q) / rate_per_quality(2) ];
			end % for
			% }BUILD CACHE_SPACE_PER_QUALITY


			cache_space_at_high_q = max(cache_space_per_quality(2:length(cache_space_per_quality) ) );

			max_cache_storage = (catalog_size * cache_to_ctlg_ratio) ...
								* cache_space_at_high_q ; % IN MB
			single_cache_storage = max_cache_storage / length(ases_with_storage);

			quality_levels = 0:quality_level_num;

			% BUILD MAX_STORAGE_AT_SINGLE_AS{
				max_storage_at_single_as = -1 .* ones(1,max(ases) );
				for as_ = ases
					if (any(ases_with_storage == as_) )
						max_storage_at_single_as(as_) = single_cache_storage;
					else
						max_storage_at_single_as(as_) = 0;
					end %if
				end %for idx_as

			% }BUILD MAX_STORAGE_AT_SINGLE_AS


			experiment_folder=sprintf("%s/examples/%s",path_base,experiment_name); 
			single_value_folder = sprintf("%s/load_%g/peer_link_scale_%g/strategy_%s", experiment_folder,load_,...
						peer_link_scale, strategy);
			single_value_folders = [single_value_folders, single_value_folder];

			% {CHECKS
			if(severe_debug)
				if (length(cache_space_per_quality) != quality_level_num+1)
					cache_space_per_quality
					quality_level_num
					error("ERROR: cache_space_per_quality and quality_level_num have a mismatching length");
				end

				if (length(cache_space_per_quality) != length(rate_per_quality) )
					cache_space_per_quality
					rate_per_quality
					error("ERROR: cache_space_per_quality and rate_per_quality have not the same length");
				end

				if (any (max_storage_at_single_as < 0) )
					max_storage_at_single_as
					ases
					error("Uninitialized values in max_storage_at_single_as");
				end
			end
			% }CHECKS

			for seed = seeds
				if generate
					specific_folder = sprintf("%s/seed_%g", single_value_folder, seed);
					command = sprintf("rm -r %s", specific_folder);
					system(command );
					command = sprintf("mkdir -p %s", specific_folder);
					system(command );

					dat_filename = sprintf("%s/scenario.dat",specific_folder);

					rand('seed',seed);
					generate_opl_dat(ases, quality_levels, catalog_size, alpha,
							rate_per_quality, 
							cache_space_per_quality, utilities,
							ASes_with_users, server, total_requests,
							arcs, max_storage_at_single_as, max_cache_storage, seed, dat_filename,
							strategy);
				endif
			endfor % seeds
		endfor % strategy for

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
