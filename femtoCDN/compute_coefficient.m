function alpha_i = compute_coefficient(in, settings, epoch)
	global COEFF_NO; global COEFF_SIMPLE; global COEFF_10; global COEFF_100;
	global COEFF_ADAPTIVE; global COEFF_ADAPTIVE_AGGRESSIVE; global COEFF_INSENSITIVE
	global COEFF_SMOOTH_TRIANGULAR; global COEFF_TRIANGULAR; global COEFF_ZERO;

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

		otherwise
			error("Coefficients not recognised");
		end%switch
end
