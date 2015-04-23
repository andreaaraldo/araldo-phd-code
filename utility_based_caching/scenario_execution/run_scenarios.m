function run_scenarios(run_list)
	max_active_opl_instances = 1;
	active_children = 0;
	for idx_run = 1:length(run_list)
		singledata = run_list(idx_run);
		dat_filename = sprintf("%s/scenario.dat",singledata.seed_folder);
		mod_filename = sprintf("%s/model.mod",singledata.fixed_data.path_base);
		
		% Check if the run was already performed
		if ( !exist(sprintf("%s/objective.csv", singledata.seed_folder) ) )
			% The run has to be done
					if (active_children == max_active_opl_instances)
						waitpid(-1);
						% One child process finished
						active_children--;
					elseif (active_children > max_active_opl_instances)
						error("Too many children launched")
					endif

					pid = fork();
					if (pid==0)
						% I am the child process
						printf("(%d/%d) Running experiment %s\n", idx_run ,length(run_list)  , singledata.seed_folder);
						time1 = time();
						launch_opl(singledata.seed_folder, mod_filename, dat_filename);
						time2 = time();
						dlmwrite(sprintf("%s/oplrun_time.csv",singledata.seed_folder), time2-time1 );						
						exit(0);
					elseif (pid > 0)
						% I am the father
						active_children ++;
					else (pid < 0)
						error ("Error in forking");
					endif
		else
			printf("Run %s already performed\n",singledata.seed_folder);
		endif % existence
	endfor

	while (active_children > 0)
		printf("Waiting for %d execution processes to finish\n", active_children);
		waitpid(-1);
		active_children--;
	end % while
end
