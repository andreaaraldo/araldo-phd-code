function parse_results(in, settings)
	HIST_REL_ERR=1; FINAL_CV=2; FINAL_OBSERVED_HIT=3; FINAL_ERR = 4; ERR_HISTORY = 5; HIST_STEPS=6; HIST_TRANSMISSIONS=7;
	HIST_AVG_ERR=8; HIST_NICE_ERR=9;
	output = HIST_TRANSMISSIONS;

	%printf("\n\n\n\n I AM PRINTING %s %d\n", settings.method, settings.coefficients);

	load(settings.outfile);
	theta_opt = in.req_proportion' * in.K;
	theta_unif = repmat(in.K/in.p, in.p, 1);


	[hist_allocation, hist_cum_tot_requests, hist_cum_hit] = compute_metrics(...
		in, settings, hist_theta, hist_num_of_misses, hist_tot_requests);


	hist_difference = ( hist_theta - repmat(theta_opt,1, size(hist_theta,2)) );
	hist_difference_sqr = hist_difference .^ 2;
	hist_difference_norm = sqrt( sum(hist_difference_sqr, 1) );
	hist_CV = sqrt( meansq( hist_difference , 1 ) ) ./ mean(hist_theta, 1) ;
	hist_nice_err = sqrt( meansq( hist_difference , 1 ) ) ./ in.K ;
	hist_rel_err = hist_difference_norm ./  repmat( norm(theta_opt), 1, size(hist_difference,2) ) ;
	hist_avg_err = (1/(in.K*in.p) ) * sum(abs( hist_difference ),1);
	hist_weigth_avg_err = (1/p) * (1./theta_opt)' * abs(hist_difference);

	switch output

		case HIST_REL_ERR
			result_file = sprintf("%s.rel_err.dat", settings.simname);
			dlmwrite(result_file,  hist_rel_err' , " " );
			printf("%s written\n", result_file);

		case FINAL_CV
			v = hist_CV( length(hist_CV ) );
			printf("%s %g %g %g\n", settings.method, in.lambda, in.T, v);

		case FINAL_ERR
			%how_many = length(hist_err);
			how_many = 1800 / in.T;
			v1 = hist_err( how_many );
			v2 = mean(hist_err(1:how_many) );
			printf("%d %d %g %g %g %g %g\n", settings.seed, settings.coefficients, in.lambda, in.K, in.T, v1, v2);

		case FINAL_OBSERVED_HIT
			v = hist_cum_hit(1);
			printf("%s %g %g %g\n", settings.method, in.lambda, in.T, v);

		case HIST_STEPS
			result_file = sprintf("%s.steps.dat", settings.simname);
			dlmwrite(result_file,  hist_a' , " " );
			printf("%s written\n", result_file);

		case HIST_AVG_ERR
			result_file = sprintf("%s.avg_err.dat", settings.simname);
			dlmwrite(result_file,  hist_avg_err' , " " );
			printf("%s written\n", result_file);

		case HIST_NICE_ERR
			result_file = sprintf("%s.nice_err.dat", settings.simname);
			dlmwrite(result_file,  hist_nice_err' , " " );
			printf("%s written\n", result_file);

		case HIST_TRANSMISSIONS
			result_file = sprintf("%s.transmissions.dat", settings.simname);
			num_of_transmissions = sum(hist_num_of_misses,1) .+ hist_updates;
			cum_num_of_transmissions = zeros(size(num_of_transmissions) );
			partial_sum = 0;
			for j=1:size(num_of_transmissions,2)
				partial_sum += num_of_transmissions(j);
				cum_num_of_transmissions(1,j) = partial_sum/j;
			end
			dlmwrite( result_file, cum_num_of_transmissions', "");
			printf("%s written\n", result_file);

		otherwise
			error "metric not recognized"
	end

end
