function launch_runs(experiment_name, data);
	run_list = divide_runs(experiment_name, data);
	generate_scenarios(run_list);
	error("I want to quit here");
	run_scenarios(run_list);
	seeds = unique([run_list.seed] );

	##############################
	##### PARSE OUTPUT ###########
	##############################
	printf("Parsing results\n");
	for idx_run = 1:length(run_list)
		singledata = run_list(idx_run);

		% Check if this run has already been parsed
		utility_file = sprintf("cat %s/utility.dat", singledata.parent_folder);
		if ( !exist(utility_file) )
			% This experiment has not been parsed
				rows_ = 1;
				columns_ = 1;
				utility_header = [];
				utility = zeros(rows_, columns_, length(seeds) );

				rows_ = singledata.catalog_size;
				columns_ = 2;
				quality_served_header = [];
				quality_served = zeros(rows_, columns_, length(seeds) );


				rows_ = singledata.catalog_size;
				columns_ = 1+length(singledata.topology.ases);
				quality_cached_per_rank_header = [];
				quality_cached_per_rank = zeros(rows_, columns_, length(seeds) );



				rows_ = 1;
				columns_ = 1;
				unsatisfied_ratio_header = [];
				unsatisfied_ratio = zeros(rows_, columns_, length(seeds) );


				idx_seed = 0;
				for seed = seeds
						idx_seed ++;
						seed_folder = sprintf("%s/seed-%g",singledata.parent_folder, seed);

						file_to_read = sprintf("%s/objective.csv", seed_folder);
						if (!length(utility_header))
							f = fopen(file_to_read, "r");
							utility_header = fgetl(f);
							fclose(f);
						endif
						value = dlmread(file_to_read,' ',1,0);
						utility(:,:,idx_seed)  = value;
						file_to_read = sprintf("%s/quality_served_per_rank.csv",  seed_folder);
						if (!length(quality_served_header))
							f = fopen(file_to_read, "r");
							quality_served_header = fgetl(f);
							fclose(f);
						endif
						value = dlmread(file_to_read,' ',1, 0);
						quality_served(:,:,idx_seed) = value;


						file_to_read = sprintf("%s/quality_cached_per_rank.csv",  seed_folder);
						if (!length(quality_cached_per_rank_header))
							f = fopen(file_to_read, "r");
							quality_cached_per_rank_header = fgetl(f);
							fclose(f);
						endif
						value = dlmread(file_to_read,' ',1, 0);
						quality_cached_per_rank(:,:,idx_seed) = value;



						file_to_read = sprintf("%s/unsatisfied_ratio.csv",  seed_folder);
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


			dim_to_reduce = 3;

						file_to_write = sprintf("%s/utility.dat",singledata.parent_folder);
						utility_mean = nanmean(utility, dim_to_reduce);
						utility_confidence = confidence_interval(utility, dim_to_reduce, ignore_NaN=true);
						f = fopen(file_to_write, "w+");
						fprintf(f, "#%s %s\n",utility_header, utility_header );
						fclose(f);
						dlmwrite(file_to_write,[utility_mean, utility_confidence], 
								"append","on", "delimiter"," ");
			

						file_to_write = sprintf("%s/quality_served.dat",singledata.parent_folder);
						quality_served_mean = nanmean(quality_served, dim_to_reduce);
						quality_served_confidence = confidence_interval(quality_served, 
								dim_to_reduce, ignore_NaN=true);
						f = fopen(file_to_write, "w+");
						fprintf(f, "#%s %s\n",quality_served_header, quality_served_header );
						fclose(f);
						dlmwrite(file_to_write,[quality_served_mean, quality_served_confidence],
								"append","on", "delimiter"," ");



						file_to_write = sprintf("%s/quality_cached_per_rank.dat",singledata.parent_folder);
						quality_cached_per_rank_mean = nanmean(quality_cached_per_rank, dim_to_reduce);
						quality_cached_per_rank_confidence = confidence_interval(quality_cached_per_rank, 
								dim_to_reduce, ignore_NaN=true);
						f = fopen(file_to_write, "w+");
						fprintf(f, "#%s %s\n",quality_cached_per_rank_header, quality_cached_per_rank_header );
						fclose(f);
						dlmwrite(file_to_write,[quality_cached_per_rank_mean, quality_cached_per_rank_confidence],
								"append","on", "delimiter"," ");


						file_to_write = sprintf("%s/unsatisfied_ratio.dat", singledata.parent_folder);
						unsatisfied_ratio_mean = nanmean(unsatisfied_ratio, dim_to_reduce);
						unsatisfied_ratio_confidence = confidence_interval(
												unsatisfied_ratio, dim_to_reduce, ignore_NaN=true);
						f = fopen(file_to_write, "w+");
						fprintf(f, "#%s %s\n",unsatisfied_ratio_header, unsatisfied_ratio_header );
						fclose(f);
						dlmwrite(file_to_write,[unsatisfied_ratio_mean, unsatisfied_ratio_confidence], 
								"append","on", "delimiter"," ");
			printf("Experiment %s parsed\n", singledata.parent_folder);
		%else
			% the experiment has already been parsed: I do nothing
		end % if existence of utility.dat
	endfor % idx_run		
end % function
