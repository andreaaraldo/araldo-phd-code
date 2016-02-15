function alpha_i = compute_coefficient(in, settings, epoch, hist_num_of_misses, hist_tot_requests,...
		last_coefficient,how_many_step_updates)

	global COEFF_NO; global COEFF_SIMPLE; global COEFF_10; global COEFF_100;
	global COEFF_ADAPTIVE; global COEFF_ADAPTIVE_AGGRESSIVE; global COEFF_INSENSITIVE;
	global COEFF_SMOOTH_TRIANGULAR; global COEFF_TRIANGULAR; global COEFF_ZERO; global COEFF_SMART;
	global COEFF_SMARTPERC25; global COEFF_SMARTSMOOTH; global COEFF_MODERATE;global COEFF_LINEAR;
	global COEFF_MODERATELONG; global COEFF_LINEARLONG; global COEFF_LINEARSMART10; 
	global COEFF_LINEARSMART100; global COEFF_LINEARCUT25; global COEFF_LINEARCUT10;
	global COEFF_LINEARHALVED5; 	global COEFF_LINEARHALVED10;

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
				hist_miss_ratio = sum(hist_num_of_misses,1) ./hist_tot_requests;
				miss_ratio_past = nanmean(hist_miss_ratio);
				if hist_miss_ratio(end) <= miss_ratio_past
					% We update
					alpha_i = a /(how_many_step_updates+1);
				else
					alpha_i = last_coefficient;
				end
			else
				alpha_i = a /(how_many_step_updates+1);
			end


		case COEFF_SMARTPERC25
			a = (in.K - in.p/2) / (in.p * in.ghat_1_norm);
			if epoch*in.T <= 360
				alpha_i=a;
			elseif epoch*in.T <=3600
				hist_miss_ratio = sum(hist_num_of_misses,1) ./hist_tot_requests;
				miss_ratio_past = prctile(hist_miss_ratio,25);
				if hist_miss_ratio(end) <= miss_ratio_past
					% We update
					alpha_i = a /(how_many_step_updates+1);
				else
					alpha_i = last_coefficient;
				end
			else
				alpha_i = a /(how_many_step_updates+1);
			end

		case COEFF_SMARTSMOOTH
			a = (in.K - in.p/2) / (in.p * in.ghat_1_norm);
			if epoch*in.T <= 360
				alpha_i=a;
			elseif epoch*in.T <=3600
				hist_miss_ratio = sum(hist_num_of_misses,1) ./hist_tot_requests;
				miss_ratio_past = nanmean(hist_miss_ratio);
				if hist_miss_ratio(end) <= miss_ratio_past
					% We update
					alpha_i = a*( ( 1 +  1 )^0.501 ) /( ( 1 +  (how_many_step_updates+1) )^0.501 );
				else
					alpha_i = last_coefficient;
				end
			else
				alpha_i = a*( ( 1 +  1 )^0.501 ) /( ( 1 +  (how_many_step_updates+1) )^0.501 );
			end

		case COEFF_SMART
			a = (in.K - in.p/2) / (in.p * in.ghat_1_norm);
			if epoch*in.T <= 360
				alpha_i=a;
			elseif epoch*in.T <=3600
				hist_miss_ratio = sum(hist_num_of_misses,1) ./hist_tot_requests;
				miss_ratio_past = nanmean(hist_miss_ratio);
				if hist_miss_ratio(end) <= miss_ratio_past
					% We update
					alpha_i = a /(how_many_step_updates+1);
				else
					alpha_i = last_coefficient;
				end
			else
				alpha_i = a /(how_many_step_updates+1);
			end

		case COEFF_MODERATE
			iterations_in_1h = 3600/in.T;
			a = (in.K - in.p/2)*( ( 1 + 0.1 * iterations_in_1h + 1 )^0.501 ) / (in.p * in.ghat_1_norm);
			alpha_i = a /( ( 1 + 0.1 * iterations_in_1h + epoch )^0.501 );

		case COEFF_MODERATELONG
			iterations_in_100h = 3600*100/in.T;
			a = (in.K - in.p/2)*( ( 1 + 0.1 * iterations_in_100h + 1 )^0.501 ) / (in.p * in.ghat_1_norm);
			alpha_i = a /( ( 1 + 0.1 * iterations_in_100h + epoch )^0.501 );


		case COEFF_LINEAR
			a = (in.K - in.p/2) / (in.p * in.ghat_1_norm);
			if epoch*in.T <=3600
				alpha_i = a - (0.9*a/3600 )*(epoch-1)*in.T; 
			else
				alpha_i = (a/10) * ( ( 1 +  1 )^0.501 ) /( 1 + (epoch - 3600/in.T +1)^0.501 );
			end

		case COEFF_LINEARSMART10
			a = (in.K - in.p/2) / (in.p * in.ghat_1_norm);
			if epoch==1
				alpha_i = a;
			elseif epoch*in.T <=3600
				alpha_i = last_coefficient - 0.9 * a * in.T / 3600;
			else
				iterations_in_10h = 3600*10/in.T;
				alpha_i = last_coefficient * (1- 1/(1+0.1*iterations_in_10h + epoch - 3600/in.T) )^0.501;
			end

		case COEFF_LINEARSMART100
			a = (in.K - in.p/2) / (in.p * in.ghat_1_norm);
			if epoch==1
				alpha_i = a;
			elseif epoch*in.T <=3600
				alpha_i = last_coefficient - 0.9 * a * in.T / 3600;
			else
				iterations_in_100h = 3600*100/in.T;
				alpha_i = last_coefficient * (1- 1/(1+0.1*iterations_in_100h + epoch - 3600/in.T) )^0.501;
			end

		case COEFF_LINEARCUT25
			a = (in.K - in.p/2) / (in.p * in.ghat_1_norm);
			if epoch==1
				alpha_i = a;
			elseif epoch*in.T <=3600
				hist_miss_ratio = sum(hist_num_of_misses,1) ./hist_tot_requests;
				miss_ratio_past = prctile(hist_miss_ratio',25)
				if hist_miss_ratio(end) <= miss_ratio_past
					% We decrease more
					alpha_i = last_coefficient * (epoch-1)/epoch;
				else
					alpha_i = last_coefficient - (last_coefficient - a/10)/(3600/in.T - epoch+1);
				end
			else
				iterations_in_10h = 3600*10/in.T;
				alpha_i = last_coefficient * (1- 1/(1+0.1*iterations_in_10h + epoch - 3600/in.T) )^0.501;
			end

		case COEFF_LINEARCUT10
			a = (in.K - in.p/2) / (in.p * in.ghat_1_norm);
			if epoch==1
				alpha_i = a;
			elseif epoch*in.T <=3600
				hist_miss_ratio = sum(hist_num_of_misses,1) ./hist_tot_requests;
				miss_ratio_past = prctile(hist_miss_ratio',10)
				if hist_miss_ratio(end) <= miss_ratio_past
					% We decrease more
					alpha_i = last_coefficient * (epoch-1)/epoch;
				else
					alpha_i = last_coefficient - (last_coefficient - a/10)/(3600/in.T - epoch+1);
				end
			else
				iterations_in_10h = 3600*10/in.T;
				alpha_i = last_coefficient * (1- 1/(1+0.1*iterations_in_10h + epoch - 3600/in.T) )^0.501;
			end

		case COEFF_LINEARHALVED5
			a = (in.K - in.p/2) / (in.p * in.ghat_1_norm);
			if epoch==1
				alpha_i = a;
			elseif epoch*in.T <=3600
				hist_miss_ratio = sum(hist_num_of_misses,1) ./hist_tot_requests;
				miss_ratio_past = prctile(hist_miss_ratio',25)
				if hist_miss_ratio(end) <= miss_ratio_past
					% We decrease more
					alpha_i = last_coefficient /2;
				else
					alpha_i = last_coefficient - (last_coefficient - a/10)/(3600/in.T - epoch+1);
				end
			else
				iterations_in_10h = 3600*10/in.T;
				alpha_i = last_coefficient * (1- 1/(1+0.1*iterations_in_10h + epoch - 3600/in.T) )^0.501;
			end


		case COEFF_LINEARHALVED10
			a = (in.K - in.p/2) / (in.p * in.ghat_1_norm);
			if epoch==1
				alpha_i = a;
			elseif epoch*in.T <=3600
				hist_miss_ratio = sum(hist_num_of_misses,1) ./hist_tot_requests;
				miss_ratio_past = prctile(hist_miss_ratio',10)
				if hist_miss_ratio(end) <= miss_ratio_past
					% We decrease more
					alpha_i = last_coefficient /2;
				else
					alpha_i = last_coefficient - (last_coefficient - a/10)/(3600/in.T - epoch+1);
				end
			else
				iterations_in_10h = 3600*10/in.T;
				alpha_i = last_coefficient * (1- 1/(1+0.1*iterations_in_10h + epoch - 3600/in.T) )^0.501;
			end


		case COEFF_LINEARLONG
			a = (in.K - in.p/2) / (in.p * in.ghat_1_norm);
			if epoch*in.T <=3600
				alpha_i = a - (0.9*a/3600 )*(epoch-1)*in.T; 
			else
				iterations_in_100h = 3600*100/in.T;
				a = (in.K - in.p/2)*( ( 1 + 0.1 * iterations_in_100h + 1 )^0.501 ) / (in.p * in.ghat_1_norm*10);
				alpha_i = a /( ( 1 + 0.1 * iterations_in_100h + (epoch - 3600/in.T +1) )^0.501 );
			end



		otherwise
			error("Coefficients not recognised");
		end%switch
end
