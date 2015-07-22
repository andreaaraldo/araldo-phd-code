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

	generate_request_files(run_list);

	for idx_run = 1:length(run_list)
		singledata = run_list(idx_run);

		% Check if the file exists
		if ( !exist(singledata.dat_filename) )

			singledata
			error('ciao');

			generate_opl_dat(singledata);
			printf(	"(%d/%d) File %s written\n", idx_run, length(run_list), ...\
					singledata.dat_filename);
		else
			printf(	"(%d/%d) File %s already written\n", idx_run, length(run_list), ...\
					singledata.dat_filename);
		end % if existence



		generate_mod_file(singledata);

	end % idx_run
end % function
