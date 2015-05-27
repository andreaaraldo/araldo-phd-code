%ciao
% timeout in seconds
function launch_opl(working_directory, mod_file, dat_file, timeout)
	new_model_filename = sprintf("%s/model.mod",working_directory);
	new_dat_filename = sprintf("%s/scenario.dat",working_directory);
	output_file = sprintf("%s/out.log",working_directory);
	if (  strcmp(new_model_filename, mod_file)==0 )
		command = sprintf("cp %s %s", mod_file, new_model_filename);
		if ( system(command ) != 0)
			error(sprintf("ERROR in creating %s", new_model_filename) );
		endif
	endif

	if ( strcmp(new_dat_filename, dat_file)==0 )
		command = sprintf("cp  %s %s", dat_file, new_dat_filename);
		if ( system(command ) != 0)
			error(sprintf("ERROR in creating %s", new_dat_filename) );
		endif
	endif

	command = sprintf("timeout %ds oplrun %s %s > %s 2>&1", ...
			timeout, new_model_filename, new_dat_filename, output_file);
	exit_code = system(command );
	if (exit_code == 124)
		printf("Not teminated after %ds\n", timeout);
	elseif ( exit_code != 0)
		error(sprintf("ERROR in the execution of command %s", command) );
	endif
end
