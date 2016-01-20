function parse_results(in, settings)
	ALL_HISTORY=1; FINAL_CV=2; FINAL_OBSERVED_HIT=3;
	output = FINAL_CV;

	load(settings.outfile);
	theta_opt = in.req_proportion' * in.K;


	[hist_allocation, hist_cum_tot_requests, hist_cum_hit] = compute_metrics(...
		in, settings, hist_theta, hist_num_of_misses, hist_tot_requests);

	hist_difference = ( hist_theta - repmat(theta_opt,1, size(hist_theta,2)) );
	hist_CV = sqrt( meansq( hist_difference , 1 ) ) ./ mean(hist_theta, 1) ;

	hist_theta
	mean(hist_theta, 1)

	switch output
		case ALL_HISTORY
			result_file = sprintf("%s.dat", settings.simname);
			hist_value = [0];
			for t=1:settings.epochs;
				hist_value= [hist_value; compute_value(in, round(hist_theta(:,t) ) ) ];
			end
			dlmwrite(result_file,  [hist_cum_tot_requests', ...
					round( hist_theta(1,:) )', hist_value, hist_MSE' ], " " );
			printf("%s written\n", result_file);

		case FINAL_CV
			v = hist_CV( length(hist_CV ) );
			printf("%s %g %g %g\n", settings.method, in.lambda, in.T, v);

		case FINAL_OBSERVED_HIT
			v = hist_cum_hit(1);
			printf("%s %g %g %g\n", settings.method, in.lambda, in.T, v);
	end

end
