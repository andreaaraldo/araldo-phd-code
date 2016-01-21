function alpha_i = compute_coefficient(in, settings, epoch)
	global COEFF_NO; global COEFF_SIMPLE; global COEFF_10; global COEFF_100;
	global COEFF_ADAPTIVE; global COEFF_ADAPTIVE_AGGRESSIVE; global COEFF_INSENSITIVE
	global COEFF_SMOOTH_TRIANGULAR; global COEFF_TRIANGULAR;

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
			if in.ghat_1_norm == 0
				error("in.ghat_1_norm is zero and the coefficient a_i cannot be computed")
			end
			a = 0.5 * in.K / (in.p * in.ghat_1_norm);
			alpha_i = a /( ( 1 + 0.1 * settings.epochs + epoch )^0.501 );

		case COEFF_ADAPTIVE_AGGRESSIVE
			if in.ghat_1_norm == 0
				error("in.ghat_1_norm is zero and the coefficient a_i cannot be computed")
			end
			a = (in.K - 0.5*in.p/2) / (in.p * in.ghat_1_norm);
			alpha_i = a /( ( 1 + 0.1 * settings.epochs + epoch )^0.501 );

		case COEFF_INSENSITIVE
			if in.ghat_1_norm == 0
				error("in.ghat_1_norm is zero and the coefficient a_i cannot be computed")
			end
			a = (in.K - 0.5*in.p/2) / (in.p * in.ghat_1_norm);
			alpha_i = a;

		case COEFF_TRIANGULAR
			if in.ghat_1_norm == 0
				error("in.ghat_1_norm is zero and the coefficient a_i cannot be computed")
			end
			a = (in.K - 0.5*in.p/2) / (in.p * in.ghat_1_norm);
			alpha_i = a /i;

		case COEFF_SMOOTH_TRIANGULAR
			if in.ghat_1_norm == 0
				error("in.ghat_1_norm is zero and the coefficient a_i cannot be computed")
			end
			a = (in.K - 0.5*in.p/2) / (in.p * in.ghat_1_norm);
			alpha_i_triangular = a /i;
			alpha_i_adapt = a /( ( 1 + 0.1 * settings.epochs + epoch )^0.501 );
			iterations_in_half_h = 60*30/in.T;
			if epoch <= iterations_in_half_h
				weight = (epoch-1)/iterations_in_half_h;
				alpha_i = weight*alpha_i_triangular + (1-weight)*alpha_i_adapt;
			else
				alpha_i = alpha_i_triangular;
			end

		otherwise
			error("Coefficients not recognised");
		end%switch
end
