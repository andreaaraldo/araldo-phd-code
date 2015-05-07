function generate_scenarios(run_list)
	% Generate the required folders
	for idx_run = 1:length(run_list)
		singledata = run_list(idx_run);
		command = sprintf("mkdir -p %s", singledata.seed_folder);
		[status, output] = system(command,1);
		if (status != 0)
			sprintf("%s\n%g\n%s\n",command, status, output);
			error("ERROR");
		end %if
	end % for idx_run (generating folders)

	printf("Going to genereate request_files\n");
	generate_request_files(run_list);

	for idx_run = 1:length(run_list)
		singledata = run_list(idx_run);

		% Check if the file exists
		if ( !exist(singledata.dat_filename) )
				generate_opl_dat(singledata);
		% else Reuse singledata.dat_filename
		end % if existence

	end % idx_run
end % function
