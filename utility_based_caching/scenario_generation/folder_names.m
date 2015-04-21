function [parent_folder, seed_folder] = folder_names(path_base, experiment_name, singledata)
	parent_folder = sprintf("%s/examples/%s/fixed-%s/%s/ctlg-%g/c2ctlg-%g/alpha-%g/load-%g/strategy-%s",...
		path_base, experiment_name, singledata.fixed_data.name, singledata.topology.name,singledata.catalog_size,
		singledata.cache_to_ctlg_ratio, singledata.alpha,
		singledata.loadd, singledata.strategy);
	seed_folder = sprintf("%s/seed-%g",parent_folder, singledata.seed);
end
