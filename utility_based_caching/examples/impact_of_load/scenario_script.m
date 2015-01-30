% Define an experiment
experiment_name = "impact_of_load";
ases = [1, 2];
quality_levels = [0, 1, 2];
catalog_size = 5;
alpha = 1;
rate_per_quality = [0, 300, 3500]; % In Kpbs
cache_space_per_quality = [100000 11.25 131.25 ]; % In MB
utility_ratio = 2; % Ratio between low and high quality utility
utility_when_not_serving = 0;
ASes_with_users = [1];
server = 2;
load_ = 5.00;
total_requests = 1921 * load_;
arcs = "{<2, 1, 490000>};"; % In Kbps
max_storage_at_single_as = (catalog_size / 100) * ...
						(cache_space_per_quality(2) + cache_space_per_quality(3) )/2  ; % IN MB
max_cache_storage = max_storage_at_single_as; % IN Mpbs
seeds = 1:2;




global severe_debug = true;
path_base = "~/software/araldo-phd-code/utility_based_caching";
addpath(sprintf("%s/scenario_generation",path_base) );
addpath(sprintf("%s/scenario_generation/michele",path_base) );
addpath(sprintf("%s/process_results",path_base) );
pkg load statistics;

experiment_folder=sprintf("%s/examples/%s",path_base,experiment_name); 





##############################
##### GENERATE SCENARIOS #####
##############################
for seed = seeds
	specific_folder = sprintf("%s/load_%g/seed_%g", experiment_folder, load_, seed);
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
	
	command = sprintf("cp %s/model.mod %s", path_base, specific_folder);
	if ( system(command ) != 0)
		error(sprintf("ERROR in copying file %s/model.mod", path_base) );
	endif
	
	command = sprintf("oplrun %s/model.mod %s", specific_folder, dat_filename);
	if ( system(command ) != 0)
		error(sprintf("ERROR in the execution of command %s", command) );
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


rows_ = 1;
columns_ = 1;
unsatisfied_ratio_header = [];
unsatisfied_ratio = zeros(rows_, columns_, length(seeds) );


for seed = seeds
		specific_folder = sprintf("%s/load_%g/seed_%g", experiment_folder, load_, seed);

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
			utility_mean = nanmean(utility, dim_to_reduce);
			utility_confidence = confidence_interval(utility, dim_to_reduce, ignore_NaN=true);
			dlmwrite("utility.dat",[utility_mean, utility_confidence], " ");

			quality_served_mean = nanmean(quality_served, dim_to_reduce);
			quality_served_confidence = confidence_interval(quality_served, dim_to_reduce, ignore_NaN=true);
			dlmwrite("quality_served.dat",[quality_served_mean, quality_served_confidence], " ");

			unsatisfied_ratio_mean = nanmean(unsatisfied_ratio, dim_to_reduce);
			unsatisfied_ratio_confidence = confidence_interval(
									unsatisfied_ratio, dim_to_reduce, ignore_NaN=true);
			dlmwrite("unsatisfied_ratio.dat",[unsatisfied_ratio_mean, unsatisfied_ratio_confidence], " ");

endfor

