function run_scenarios(run_list)
	for idx_run = 1:length(run_list)
		singledata = run_list(idx_run);
		
		% Check if the run was already performed
		if ( !exist(sprintf("%s/objective.csv", singledata.seed_folder) ) )
			% The run has to be done
			printf("(%d/%d) Running experiment %s\n", idx_run ,length(run_list)  , singledata.seed_folder);
			time1 = time();
			launch_opl(singledata.seed_folder, singledata.mod_filename, singledata.dat_filename);
			time2 = time();
			dlmwrite(sprintf("%s/oplrun_time.csv",singledata.seed_folder), time2-time1 );						
		else
			printf("Run %s already performed\n",singledata.seed_folder);
		endif % existence
	endfor
end
