%ciao
generate = true;
run_ = true;

% Define an experiment
experiment_name = "impact_of_inter_link";
ases = [1, 2, 3];
quality_levels = [0, 1, 2];
catalog_size = 1000;
alpha = 1;
rate_per_quality = [0, 300, 3500]; % In Kpbs
cache_space_per_quality = [0 11.25 131.25 ]; % In MB
utility_ratio = 2; % Ratio between low and high quality utility
utility_when_not_serving = 0;
ASes_with_users = [1, 2];
server = 3;
load_ = 0.5;
total_requests = 2800 * load_ * length(ASes_with_users);
	inter_as_link = 100000;
	external_link = 490000;
	arcs = sprintf("{<1, 2, %g>, <2, 1, %g>, <2, 3, %g>, <3, 2, %g>, <1, 3, %g>, <3, 1, %g>};",...
				inter_as_link, inter_as_link, ...
				external_link, external_link, external_link, external_link); % In Kbps
	max_storage_at_single_as = (catalog_size / 100) * ...
							(cache_space_per_quality(2) + cache_space_per_quality(3) )/2  ; % IN MB
	max_cache_storage = max_storage_at_single_as*2; % IN Mpbs
	seeds = 1:1;



	global severe_debug = true;
	path_base = "~/software/araldo-phd-code/utility_based_caching";
	addpath(sprintf("%s/scenario_generation",path_base) );
	addpath(sprintf("%s/scenario_generation/michele",path_base) );
	addpath(sprintf("%s/process_results",path_base) );
	pkg load statistics;

	experiment_folder=sprintf("%s/examples/collaboration/%s",path_base,experiment_name); 

	single_value_folder = sprintf("%s/inter_link_%g", experiment_folder, inter_as_link);





	##############################
	##### GENERATE SCENARIOS #####
	##############################
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
					cache_space_per_quality, utility_ratio, utility_when_not_serving, 
					ASes_with_users, server, total_requests,
					arcs, max_storage_at_single_as, max_cache_storage, seed, dat_filename);
		endif
	
		if run_
			command = sprintf("cp %s/model.mod %s", path_base, specific_folder);
			if ( system(command ) != 0)
				error(sprintf("ERROR in copying file %s/model.mod", path_base) );
			endif
	
			command = sprintf("oplrun %s/model.mod %s", specific_folder, dat_filename);
			if ( system(command ) != 0)
				error(sprintf("ERROR in the execution of command %s", command) );
			endif
		endif
	endfor

	##############################
	##### PARSE OUTPUT ###########
	##############################
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


	for seed = seeds
			specific_folder = sprintf("%s/seed_%g", single_value_folder, seed);

			file_to_read = sprintf("%s/objective.csv", specific_folder);
			if (!length(utility_header))
				f = fopen(file_to_read, "r");
				utility_header = fgetl(f);
				fclose(f);
			endif
			value = dlmread(file_to_read,' ',1,0);
			utility(:,:,seed)  = value;

			file_to_read = sprintf("%s/quality_served_per_rank.csv",  specific_folder);
			if (!length(quality_served_header))
				f = fopen(file_to_read, "r");
				quality_served_header = fgetl(f);
				fclose(f);
			endif
			value = dlmread(file_to_read,' ',1, 0);
			quality_served(:,:,seed) = value;


			file_to_read = sprintf("%s/quality_cached_per_rank.csv",  specific_folder);
			if (!length(quality_cached_per_rank_header))
				f = fopen(file_to_read, "r");
				quality_cached_per_rank_header = fgetl(f);
				fclose(f);
			endif
			value = dlmread(file_to_read,' ',1, 0);
			quality_cached_per_rank(:,:,seed) = value;



			file_to_read = sprintf("%s/unsatisfied_ratio.csv",  specific_folder);
			if (!length(unsatisfied_ratio_header) )
				f = fopen(file_to_read, "r");
				unsatisfied_ratio_header = fgetl(f);
				fclose(f);
			endif
			value = dlmread(file_to_read,' ',1,0);
			unsatisfied_ratio(:,:,seed)  = value;
	endfor

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

	endfor

