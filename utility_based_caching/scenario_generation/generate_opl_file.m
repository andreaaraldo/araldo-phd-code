% This function is called by 

function opl_string = generate_opl_file(run_, output_file)
	write_to_file = true;
	opl_string = "";

	field_names = {"NumASes", "NumObjects", \
				"ObjectReachabilityMatrix", "TrafficDemand", "TransitPrice", \
				"CachePrice", "MaxCachePerBorderRouter", "MaxCoreCache",\
				"MaxTotalCache"};

	if run_.NumScenarios > 1
		field_names = {"NumScenarios", "RealizationProbabilities", field_names};
	endif

	%{purge_option = [true, true, true, false, \
	%				false, false, false, \
	%				true, true, true, \
	%				true];
	purge_option = [true, true, true, true, \
					true, true, true, \
					true, true, true, \
					true];


	if write_to_file
		f=fopen(output_file,"w");
		for i = 1:length(field_names)
			field_name = field_names{i};
			field_value = run_.(field_name);
			opl_representation_ = opl_representation(field_name, field_value, purge_option(i) );
			fprintf(f,"%s\n", opl_representation_);
		endfor
		fclose(f);

		disp(["The output has been written in ",output_file])
	end
end % of function
