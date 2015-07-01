function opl_string = generate_opl_file(run_, output_file)
	write_to_file = false;
	opl_string = "";
	field_names = {"NumASes", "NumObjects", "NumScenarios", "RealizationProbabilities", \
				"ObjectReachabilityMatrix", "TrafficDemand", "TransitPrice", \
				"CachePrice", "MaxCachePerBorderRouter", "MaxCoreCache",\
				"MaxTotalCache"};
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
			fprintf("%s\n", opl_representation(field_name, run_.(field_name), purge_option(i) ) );
		end % of for
		fclose(f);
	end
end % of function
