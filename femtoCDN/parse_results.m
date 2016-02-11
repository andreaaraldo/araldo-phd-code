function parse_results(in, settings)
	HIST_REL_ERR=1; FINAL_CV=2; FINAL_OBSERVED_HIT=3; FINAL_ERR = 4; ERR_HISTORY = 5; HIST_STEPS=6; 
	HIST_MISSES=7; HIST_AVG_ERR=8; HIST_NICE_ERR=9; HIST_INFTY_ERR=10; HIST_GHAT_AVG=11;
	HIST_POINTMISSES=12; HIST_WINDOWEDMISSES=13; MISSES_AFTER_30_MIN=14; HIST_ALLOCATION=15;

	output = HIST_ALLOCATION;

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

		case HIST_GHAT_AVG
			partial_sum = zeros(in.p,1);
			hist_ghat_avg = [];
			for t=1:size(hist_ghat,2)
				avg = sum( hist_ghat(:,max(1,t-99):t), 2) ./ (t+1- max(1,t-99) );
				hist_ghat_avg = [hist_ghat_avg, sqrt( sum( avg .^2 ) ) ];
			end
			result_file = sprintf("%s.ghat_avg.dat", settings.simname);
			dlmwrite(result_file,  hist_ghat_avg' , " " );
			printf("%s written\n", result_file);
			

		case HIST_INFTY_ERR
			hist_infty_err = norm(hist_difference, Inf,"cols");
			result_file = sprintf("%s.infty_err.dat", settings.simname);
			dlmwrite(result_file,  hist_infty_err' , " " );
			printf("%s written\n", result_file);

		case HIST_REL_ERR
			result_file = sprintf("%s.rel_err.dat", settings.simname);
			dlmwrite(result_file,  hist_rel_err' , " " );
			printf("%s written\n", result_file);

		case FINAL_CV
			v = hist_CV( length(hist_CV ) );
			printf("%s %g %g %g\n", settings.method, in.lambda, in.T, v);

		case MISSES_AFTER_30_MIN
			iteration = ceil(1800/in.T);
			v=1-hist_cum_hit(iteration);
			printf("%s %d %g %g %g\n", settings.method, settings.coefficients, in.T, v, in.lambda);

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

		case HIST_MISSES
			result_file = sprintf("%s.misses.dat", settings.simname);
			dlmwrite( result_file, (1-hist_cum_hit)', "");
			printf("%s written\n", result_file);

		case HIST_POINTMISSES
			pointmisses = sum(hist_num_of_misses,1) ./ hist_tot_requests;
			result_file = sprintf("%s.pointmisses.dat", settings.simname);
			dlmwrite( result_file, pointmisses', "");
			printf("%s written\n", result_file);

		case HIST_WINDOWEDMISSES
			win_size = 600; % in seconds
			iterations = ceil(win_size/in.T);
			misses_across_CPs = sum(hist_num_of_misses,1);
			windowed_misses = zeros(size(hist_tot_requests) );
			for t=1:length(hist_tot_requests)
				selector = max(t+1-iterations, 1):t;
				windowed_misses(1,t) = sum(misses_across_CPs(1, selector) ) / ...
					sum(hist_tot_requests(1, selector) );
			end
			result_file = sprintf("%s.windowedmisses.dat", settings.simname);
			dlmwrite( result_file, windowed_misses', "");
			printf("%s written\n", result_file);

		case HIST_ALLOCATION
			result_file = sprintf("%s.allocation.dat", settings.simname);
			hist_theta'
			error "ciao"
			dlmwrite( result_file, hist_theta', "");
			printf("%s written\n", result_file);
			

		otherwise
			error "metric not recognized"
	end

end
