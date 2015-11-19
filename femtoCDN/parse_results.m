function parse_results(in, settings)
	load(settings.infile);
	hist_value = [0];
	for t=1:settings.epochs;
		hist_value= [hist_value; compute_value(in, round(vc) ) ];
	end
	dlmwrite(settings.outfile,  [hist_cum_observed_req', round( hist_vc(1,:) )', hist_value ], " " );
	printf("%s written", settings.outfile);
end
