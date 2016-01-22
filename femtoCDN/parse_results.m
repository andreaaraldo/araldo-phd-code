function parse_results(in, settings)
	ALL_HISTORY=1; FINAL_CV=2; FINAL_OBSERVED_HIT=3; FINAL_ERR = 4;
	output = FINAL_ERR;

	%printf("\n\n\n\n I AM PRINTING %s %d\n", settings.method, settings.coefficients);

	load(settings.outfile);
	theta_opt = in.req_proportion' * in.K;


	[hist_allocation, hist_cum_tot_requests, hist_cum_hit] = compute_metrics(...
		in, settings, hist_theta, hist_num_of_misses, hist_tot_requests);

	hist_difference = ( hist_theta - repmat(theta_opt,1, size(hist_theta,2)) );
	hist_difference_sqr = hist_difference .^ 2;
	hist_difference_norm = sqrt( sum(hist_difference_sqr, 1) );
	hist_CV = sqrt( meansq( hist_difference , 1 ) ) ./ mean(hist_theta, 1) ;
	hist_err = hist_difference_norm ./  repmat( norm(theta_opt), 1, size(hist_difference,2) )  ;
	%{
	coefficiente = hist_a
	[ix, iy] = find(hist_theta<0);
	primo_negativo = min(iy);
	theta_prima = hist_theta(:, primo_negativo-1 )'
	ghat_corrente = hist_ghat(:, primo_negativo )'
	a_corrente = hist_a(:, primo_negativo )'
	theta_dopo = hist_theta(:, primo_negativo )'
	ghat_dopo = hist_ghat(:, primo_negativo+1 )'
	a_dopo = hist_a(:, primo_negativo+1 )'
	theta_dopo_ancora = hist_theta(:, primo_negativo+1 )'
	configurazione = round(hist_theta(:, size(hist_theta, 2) ) )
<<<<<<< HEAD
	%}
	configurazione = round(hist_theta(:, 1:50 )
	error("ciao");
=======
>>>>>>> b6f7787c7d5733d6437950703cb43fa39e8460c9
	%errore = hist_err'
	%}
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

		case FINAL_ERR
			how_many = length(hist_err);
			%how_many = 1800 / in.T;
			v1 = hist_err( how_many );
			v2 = mean(hist_err(1:how_many) );
			printf("%s %d %g %g %g %g %g\n", settings.method, settings.coefficients, in.lambda, in.K, in.T, v1, v2);

		case FINAL_OBSERVED_HIT
			v = hist_cum_hit(1);
			printf("%s %g %g %g\n", settings.method, in.lambda, in.T, v);
	end

end
