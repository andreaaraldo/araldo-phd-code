% Called by scenario_script.m
function generate_mod_file(singledata)
mod_filename = sprintf("%s/model.mod",singledata.fixed_data.path_base);
	copyfile("~/software/araldo-phd-code/utility_based_caching/model.mod",...
			 singledata.mod_filename );

	cachetype="";
	switch singledata.customtype
		case "int"
			cachetype="boolean";
		case "float"
			cachetype="float";
	end

	command = sprintf("sed -i.bak 's_/\\*%s_ _' %s; sed -i.bak 's_%s\\*/_ _' %s; sed -i.bak 's_CUSTOMTYPE_%s_' %s; sed -i.bak 's_CACHETYPE_%s_' %s ",...
			singledata.strategy,singledata.mod_filename, singledata.strategy,singledata.mod_filename,...
<<<<<<< HEAD
			singledata.customtype, singledata.mod_filename,...
			cachetype, singledata.mod_filename);
	command
	error "ciao"
=======
			singledata.customtype, singledata.mod_filename );
>>>>>>> cd41c88c1bd484faeb053933e8c841cfd5d0fb56
	[status, output] = system(command,1);

	if (status != 0)
		status
		output
		error("ERROR");
	end %if
endfunction
