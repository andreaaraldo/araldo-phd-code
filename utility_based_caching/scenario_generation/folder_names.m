function [parent_folder, seed_folder, request_file] = folder_names(path_base, experiment_name, singledata)
	grandfather_folder = sprintf("%s/examples/%s/fixed-%s/%s/ctlg-%g/c2ctlg-%g/alpha-%g/load-%g",...
		path_base, experiment_name, singledata.fixed_data.name, singledata.topology.name,singledata.catalog_size,
		singledata.cache_to_ctlg_ratio, singledata.alpha, singledata.loadd);
	request_file_folder = sprintf("%s/examples/%s/request_files/%s/ctlg-%g/alpha-%g/load-%g/seed-%g",...
		path_base, experiment_name, singledata.topology.name,singledata.catalog_size,
		singledata.alpha, singledata.loadd, singledata.seed);

	%{ CREATE REQUEST_FILE_FOLDER	
	command = sprintf("mkdir -p %s", request_file_folder);
	[status, output] = system(command,1);
	if (status != 0)
		sprintf("%s\n%g\n%s\n",command, status, output);
		error("ERROR");
	end %if
	%} CREATE REQUEST_FILE_FOLDER

	request_file = sprintf("%s/req.dat", request_file_folder);
	parent_folder = sprintf("%s/strategy-%s", grandfather_folder,singledata.strategy);
	seed_folder = sprintf("%s/seed-%g",parent_folder, singledata.seed);
end
