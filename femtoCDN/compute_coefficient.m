function alpha_i = compute_coefficient(in, settings, epoch, hist_num_of_misses, last_coefficient,last_cofficient_update_iteration)
	global COEFF_NO; global COEFF_SIMPLE; global COEFF_10; global COEFF_100;
	global COEFF_ADAPTIVE; global COEFF_ADAPTIVE_AGGRESSIVE; global COEFF_INSENSITIVE
	global COEFF_SMOOTH_TRIANGULAR; global COEFF_TRIANGULAR; global COEFF_ZERO; global COEFF_SMART;

	if in.ghat_1_norm == 0
		in.ghat_1_norm = 1;
	end


	switch settings.coefficients
		case COEFF_SIMPLE
			alpha_i = 1.0/epoch;

		case COEFF_NO
			alpha_i = 1;

		case COEFF_10
			alpha_i = 1.0/( 1+ floor(epoch/10) );

		case COEFF_100
			alpha_i = 1.0/( 1+ floor(epoch/100) );

		case COEFF_ADAPTIVE
			a = 0.5 * in.K / (in.p * in.ghat_1_norm);
			alpha_i = a /( ( 1 + 0.1 * settings.epochs + epoch )^0.501 );

		case COEFF_ADAPTIVE_AGGRESSIVE
			a = (in.K - 0.5*in.p/2) / (in.p * in.ghat_1_norm);
			alpha_i = a /( ( 1 + 0.1 * settings.epochs + epoch )^0.501 );

		case COEFF_INSENSITIVE
			a = (in.K - 0.5*in.p/2) / (in.p * in.ghat_1_norm);
			alpha_i = a;

		case COEFF_TRIANGULAR
			a = (in.K - 0.5*in.p/2) / (in.p * in.ghat_1_norm);
			alpha_i = a /epoch;

		case COEFF_SMOOTH_TRIANGULAR
			a = (in.K - 0.5*in.p/2) / (in.p * in.ghat_1_norm);
			alpha_i_triangular = a /epoch;
			alpha_i_adapt = a /( ( 1 + 0.1 * settings.epochs + epoch )^0.501 );
			iterations_in_half_h = 60*30/in.T;
			if epoch <= iterations_in_half_h
				weight = (epoch-1)/iterations_in_half_h;
				alpha_i = weight*alpha_i_triangular + (1-weight)*alpha_i_adapt;
			else
				alpha_i = alpha_i_triangular;
			end

		case COEFF_ZERO
			alpha_i = 0;

		case COEFF_SMART
			a = (in.K - 0.5*in.p/2) / (in.p * in.ghat_1_norm);
			if epoch*in.T <= 360
				alpha_i=a;
			elseif epoch*in.T <=3600
				hist_infty_err = compute_hist_infty_err(in.theta_opt, in.hist_theta);
				avg_error_experienced_so_far = mean(hist_infty_err);
				if hist_infty_err(end) <= avg_error_experienced_so_far
					% We update
					alpha_i = a /(last_cofficient_update_iteration+1);
				else
					alpha_i = last_coefficient;
				end
			else
				alpha_i = a /(last_cofficient_update_iteration+1);
			end

		otherwise
			error("Coefficients not recognised");
		end%switch
end
