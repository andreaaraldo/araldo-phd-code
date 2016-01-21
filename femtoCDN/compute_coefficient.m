function alpha_i = compute_coefficient(in, settings, epoch)
	global COEFF_NO; global COEFF_SIMPLE; global COEFF_10; global COEFF_100;
	global COEFF_ADAPTIVE; global COEFF_ADAPTIVE_AGGRESSIVE;

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
		otherwise
			error("Coefficients not recognised");
		end%switch
end
