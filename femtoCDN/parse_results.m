function parse_results(in, settings)
	ALL_HISTORY=1; FINAL_CV=2; FINAL_OBSERVED_HIT=3; FINAL_ERR = 4; ERR_HISTORY = 5;
	output = ERR_HISTORY;

	%printf("\n\n\n\n I AM PRINTING %s %d\n", settings.method, settings.coefficients);

	load(settings.outfile);
	theta_opt = in.req_proportion' * in.K;


	[hist_allocation, hist_cum_tot_requests, hist_cum_hit] = compute_metrics(...
		in, settings, hist_phi, hist_num_of_misses, hist_tot_requests);

	hist_difference = ( hist_phi - repmat(theta_opt,1, size(hist_phi,2)) );
	hist_difference_sqr = hist_difference .^ 2;
	hist_difference_norm = sqrt( sum(hist_difference_sqr, 1) );
	hist_CV = sqrt( meansq( hist_difference , 1 ) ) ./ mean(hist_phi, 1) ;
	hist_err = hist_difference_norm ./  repmat( norm(theta_opt), 1, size(hist_difference,2) )  ;

	switch output

		case ALL_HISTORY
			result_file = sprintf("%s.dat", settings.simname);
			hist_value = [0];
			for t=1:settings.epochs;
				hist_value= [hist_value; compute_value(in, round(hist_theta(:,t) ) ) ];
			end
			dlmwrite(result_file,  [hist_cum_tot_requests', ...
					round( hist_theta(1,:) )', hist_value, hist_err' ], " " );
			printf("%s written\n", result_file);

		case FINAL_CV
			v = hist_CV( length(hist_CV ) );
			printf("%s %g %g %g\n", settings.method, in.lambda, in.T, v);

		case FINAL_ERR
			how_many = length(hist_err);
			%how_many = 1800 / in.T;
			v1 = hist_err( how_many );
			v1 = round(v1*100);
			v2 = mean(hist_err(1:how_many) );
			v2 = round(v2*100);
			printf("%s %d %s %g %g %g %g %g\n", settings.method, settings.coefficients, settings.balancer_str, in.lambda, in.K, in.T, v1, v2);

		case FINAL_OBSERVED_HIT
			v = hist_cum_hit(1);
			printf("%s %g %g %g\n", settings.method, in.lambda, in.T, v);
	end

end
