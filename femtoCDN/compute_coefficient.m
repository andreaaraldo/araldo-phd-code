function alpha_i = compute_coefficient(settings, epoch)

	switch settings.coefficients
		case "simple"
			alpha_i = 1.0/epoch;
		case "no"
			alpha_i = 1;
		case "every10"
			alpha_i = 1.0/( 1+ floor(epoch/10) );
		case "every100"
			alpha_i = 1.0/( 1+ floor(epoch/100) );
		otherwise
			error("Coefficients not recognised");
		end%switch


end
