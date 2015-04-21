function generate_scenarios(run_list)
	active_children = 0;

	for idx_run = 1:length(run_list)
		singledata = run_list(idx_run);
		command = sprintf("mkdir -p %s", singledata.seed_folder);
		[status, output] = system(command,1);
		if (status != 0)
			sprintf("%s\n%g\n%s\n",command, status, output);
			error("ERROR");
		end %if

		%{ DEBUG CHECK
			if (active_children > singledata.fixed_data.parallel_processes)
				error(sprintf("active_children=%g", active_children) );
			end %if
		%} DEBUG CHECK

		% Check if the file exists
		if ( !exist(singledata.dat_filename) )
			% file does not exist and I'm going to create it. Anyway, if there are too many
			% processes I wait for one of them to finish
			if (active_children == singledata.fixed_data.parallel_processes)
				waitpid(-1);
				% One child process finished
				active_children--;
			endif

			pid = fork();
			if (pid==0)
				% I am the child process and I generate the run
				generate_opl_dat(singledata);
				exit(0);
			elseif (pid > 0)
				% I am the father
				active_children ++;
			else (pid < 0)
				error ("Error in forking");
			endif

		else
			printf("Reusing %s\n",singledata.dat_filename);		
		end % if existence

	end % idx_run

	while (active_children > 0)
		printf("Waiting for %d processes to finish\n", active_children);
		waitpid(-1);
		active_children--;
	end % while
end % function
