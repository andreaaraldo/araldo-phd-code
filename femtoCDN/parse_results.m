function parse_results(in, settings)
	load(settings.outfile);
	result_file = sprintf("%s.dat", settings.simname);
	hist_value = [0];
	for t=1:settings.epochs;
		hist_value= [hist_value; compute_value(in, round(hist_theta(:,t) ) ) ];
	end
	dlmwrite(result_file,  [hist_cum_observed_req', ...
			round( hist_theta(1,:) )', hist_value, hist_MSE ], " " );
	printf("%s written\n", result_file);
end
