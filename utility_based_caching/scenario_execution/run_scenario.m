function run_scenarios(run_list)
	active_children = 0;
	for idx_run = 1:length(run_list)
		singledata = run_list(idx_run);
		dat_filename = sprintf("%s/scenario.dat",singledata.seed_folder);
		mod_filename = sprintf("%s/model.mod",singledata.fixed_data.path_base);

					if (active_children > parallel_processes)
						waitpid(-1);
						% One child process finished
						active_children--;
					endif

					pid = fork();
					if (pid==0)
						% I am the child process
						printf("Running experiment %s\n", singledata.seed_folder);
						launch_opl(singledata.seed_folder, mod_filename, dat_filename);
						exit(0);
					elseif (pid > 0)
						% I am the father
						active_children ++;
					else (pid < 0)
						error ("Error in forking");
					endif
	
			while (active_children > 0)
				printf("Waiting for %d processes to finish\n", active_children);
				waitpid(-1);
				active_children--;
			end % while
	end % idx_run for
end
