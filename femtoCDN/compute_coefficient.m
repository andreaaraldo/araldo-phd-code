function alpha_i = compute_coefficient(settings, epoch)
	global COEFF_NO; global COEFF_SIMPLE; global COEFF_10; global COEFF_100;

	switch settings.coefficients
		case COEFF_SIMPLE
			alpha_i = 1.0/epoch;
		case COEFF_NO
			alpha_i = 1;
		case COEFF_10
			alpha_i = 1.0/( 1+ floor(epoch/10) );
		case COEFF_100
			alpha_i = 1.0/( 1+ floor(epoch/100) );
		otherwise
			error("Coefficients not recognised");
		end%switch
end
