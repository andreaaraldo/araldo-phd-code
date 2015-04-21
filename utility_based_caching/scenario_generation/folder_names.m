function [parent_folder, seed_folder, request_file] = folder_names(path_base, experiment_name, singledata)
	grandfather_folder = sprintf("%s/examples/%s/fixed-%s/%s/ctlg-%g/c2ctlg-%g/alpha-%g/load-%g",...
		path_base, experiment_name, singledata.fixed_data.name, singledata.topology.name,singledata.catalog_size,
		singledata.cache_to_ctlg_ratio, singledata.alpha, singledata.loadd);
	request_file = sprintf("%s/requests.dat", grandfather_folder);
	parent_folder = sprintf("%s/strategy-%s", grandfather_folder,singledata.strategy);
	seed_folder = sprintf("%s/seed-%g",parent_folder, singledata.seed);
end
