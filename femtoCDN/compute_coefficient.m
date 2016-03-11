function alpha_i = compute_coefficient(in, settings, epoch, hist_num_of_misses, hist_tot_requests,...
		last_coefficient,how_many_step_updates, hist_ghat)

	global COEFF_NO; global COEFF_SIMPLE; global COEFF_10; global COEFF_100;
	global COEFF_ADAPTIVE; global COEFF_ADAPTIVE_AGGRESSIVE; global COEFF_INSENSITIVE;
	global COEFF_SMOOTH_TRIANGULAR; global COEFF_TRIANGULAR; global COEFF_ZERO; global COEFF_SMART;
	global COEFF_SMARTPERC25; global COEFF_SMARTSMOOTH; global COEFF_MODERATE;global COEFF_LINEAR;
	global COEFF_MODERATELONG; global COEFF_LINEARLONG; global COEFF_LINEARSMART10; 
	global COEFF_LINEARSMART100; global COEFF_LINEARCUT25; global COEFF_LINEARCUT10;
	global COEFF_LINEARHALVED5; global COEFF_LINEARHALVED10;
	global COEFF_LINEARCUTCAUTIOUS10;	global COEFF_LINEARCUTCAUTIOUS25;
	global COEFF_LINEARCUTCAUTIOUSMODERATE10; global COEFF_LINEARCUTCAUTIOUS10D2;
	global COEFF_LINEARCUTCAUTIOUS10D4; global COEFF_LINEARCUTCAUTIOUS10D8; 
	global COEFF_LINEARCUTCAUTIOUS10D16; global COEFF_LINEARCUTCAUTIOUS10Dp;
	global COEFF_MODERATELONGNEW; global COEFF_MODERATENEW; global COEFF_LINEARHALVED5REINIT30MIN;
	global COEFF_LINEARHALVED5REINIT1DAY; global COEFF_LINEARHALVED5REINIT2H; global COEFF_LINEARHALVED5REINIT3H;

	ghat_1 = hist_ghat(:,1);
	ghat_1_norm = norm(ghat_1);


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
			a = 0.5 * in.K / (in.p * ghat_1_norm);
			alpha_i = a /( ( 1 + 0.1 * settings.epochs + epoch )^0.501 );

		case COEFF_ADAPTIVE_AGGRESSIVE
			a = (in.K - 0.5*in.p/2) / (in.p * ghat_1_norm);
			alpha_i = a /( ( 1 + 0.1 * settings.epochs + epoch )^0.501 );

		case COEFF_INSENSITIVE
			a = (in.K - 0.5*in.p/2) / (in.p * ghat_1_norm);
			alpha_i = a;

		case COEFF_TRIANGULAR
			ghat_measure = 0; t=1;
			while ghat_measure==0 && t<=size(hist_ghat,2)
				ghat_measure=norm(hist_ghat(:,t)  );
				t++;
			end
			if ghat_measure>0
				a = (in.K - in.p/2) / (in.p * ghat_measure);
			else
				a=0;
			end
			alpha_i = a /epoch;

		case COEFF_SMOOTH_TRIANGULAR
			a = (in.K - 0.5*in.p/2) / (in.p * ghat_1_norm);
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
			a = (in.K - 0.5*in.p/2) / (in.p * ghat_1_norm);
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
			a = (in.K - in.p/2) / (in.p * ghat_1_norm);
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
			a = (in.K - in.p/2) / (in.p * ghat_1_norm);
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
			a = (in.K - in.p/2) / (in.p * ghat_1_norm);
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
			ghat_measure = 0; t=1;
			while ghat_measure==0 && t<=size(hist_ghat,2)
				ghat_measure=norm(hist_ghat(:,t)  );
				t++;
			end
			if ghat_measure>0
				a = (in.K - in.p/2)*( ( 1 + 0.1 * iterations_in_1h + 1 )^0.501 ) / (in.p * ghat_measure);
			else
				a=0;
			end
			alpha_i = a /( ( 1 + 0.1 * iterations_in_1h + epoch )^0.501 );

		case COEFF_MODERATENEW
			ghat_measure = sum( abs(ghat_1) );
			how_many_initial_iterations=floor(360/in.T);
			iterations_in_10h = 3600*10/in.T;
			a = (in.K - in.p/2)*( ( 1 + 0.1 * iterations_in_10h + 1 )^0.501 ) /...
				(how_many_initial_iterations * ghat_measure/in.p);
			alpha_i = a /( ( 1 + 0.1 * iterations_in_10h + epoch )^0.501 );

		case COEFF_MODERATELONG
			iterations_in_100h = 3600*100/in.T;
			a = (in.K - in.p/2)*( ( 1 + 0.1 * iterations_in_100h + 1 )^0.501 ) / (in.p * ghat_1_norm);
			alpha_i = a /( ( 1 + 0.1 * iterations_in_100h + epoch )^0.501 );

		case COEFF_MODERATELONGNEW
			ghat_measure = sum( abs(ghat_1) );
			how_many_initial_iterations=floor(360/in.T);
			iterations_in_100h = 3600*100/in.T;
			a = (in.K - in.p/2)*( ( 1 + 0.1 * iterations_in_100h + 1 )^0.501 ) /...
				(how_many_initial_iterations * ghat_measure/in.p);
			alpha_i = a /( ( 1 + 0.1 * iterations_in_100h + epoch )^0.501 );

		case COEFF_LINEAR
			a = (in.K - in.p/2) / (in.p * ghat_1_norm);
			if epoch*in.T <=3600
				alpha_i = a - (0.9*a/3600 )*(epoch-1)*in.T; 
			else
				alpha_i = (a/10) * ( ( 1 +  1 )^0.501 ) /( 1 + (epoch - 3600/in.T +1)^0.501 );
			end

		case COEFF_LINEARSMART10
			a = (in.K - in.p/2) / (in.p * ghat_1_norm);
			if epoch==1
				alpha_i = a;
			elseif epoch*in.T <=3600
				alpha_i = last_coefficient - 0.9 * a * in.T / 3600;
			else
				iterations_in_10h = 3600*10/in.T;
				alpha_i = last_coefficient * (1- 1/(1+0.1*iterations_in_10h + epoch - 3600/in.T) )^0.501;
			end

		case COEFF_LINEARSMART100
			error "copy and paste from LINEARSMART10"

		case COEFF_LINEARCUT25
			error "copy and paste from LINEARCUT10"

		case COEFF_LINEARCUT10
			a = (in.K - in.p/2) / (in.p * ghat_1_norm);
			if epoch==1
				alpha_i = a;
			elseif epoch*in.T <=3600
				hist_miss_ratio = sum(hist_num_of_misses,1) ./hist_tot_requests;
				miss_ratio_past = prctile(hist_miss_ratio',10);
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

		case COEFF_LINEARCUTCAUTIOUS10
			a = (in.K - in.p/2) / (in.p * ghat_1_norm);
			if epoch*in.T <=360
				alpha_i = a;
			elseif epoch*in.T <=3600
				hist_miss_ratio = sum(hist_num_of_misses,1) ./hist_tot_requests;
				miss_ratio_past = prctile(hist_miss_ratio',10);
				if hist_miss_ratio(end) <= miss_ratio_past
					% We decrease more
					alpha_i_first = last_coefficient * (epoch-360/in.T )/ (epoch-360/in.T+1);
					alpha_i_second = last_coefficient - (last_coefficient - a/10)/(3600/in.T - epoch+1);
					alpha_i=min(alpha_i_first, alpha_i_second);
					alpha_i=max(alpha_i, a/10);
				else
					alpha_i = last_coefficient - (last_coefficient - a/10)/(3600/in.T - epoch+1);
				end
			else
				iterations_in_10h = 3600*10/in.T;
				alpha_i = last_coefficient * (1- 1/(1+0.1*iterations_in_10h + epoch - 3600/in.T) )^0.501;
			end


		case COEFF_LINEARCUTCAUTIOUS10D4
			error "Copy and paste from LINEARCUTCAUTIOUS10D8"

		case COEFF_LINEARCUTCAUTIOUS10D2
			error "Copy and paste from LINEARCUTCAUTIOUS10D8"

		case COEFF_LINEARCUTCAUTIOUS10D8
			ghat_measure = sum( abs(ghat_1) );
			how_many_initial_iterations=floor(360/in.T);
			a = (in.K - in.p/2) / (how_many_initial_iterations * ghat_measure/8);
			if epoch*in.T <=360
				alpha_i = a;
			elseif epoch*in.T <=3600
				hist_miss_ratio = sum(hist_num_of_misses,1) ./hist_tot_requests;
				miss_ratio_past = prctile(hist_miss_ratio',10);
				if hist_miss_ratio(end) <= miss_ratio_past
					% We decrease more
					alpha_i_first = last_coefficient * (epoch-360/in.T )/ (epoch-360/in.T+1);
					alpha_i_second = last_coefficient - (last_coefficient - a/10)/(3600/in.T - epoch+1);
					alpha_i=min(alpha_i_first, alpha_i_second);
					alpha_i=max(alpha_i, a/10);
				else
					alpha_i = last_coefficient - (last_coefficient - a/10)/(3600/in.T - epoch+1);
				end
			else
				iterations_in_10h = 3600*10/in.T;
				alpha_i = last_coefficient * (1- 1/(1+0.1*iterations_in_10h + epoch - 3600/in.T) )^0.501;
			end

		case COEFF_LINEARCUTCAUTIOUS10D16
			error "Copy and paste from LINEARCUTCAUTIOUS10D8"


		case COEFF_LINEARCUTCAUTIOUS10Dp
			ghat_measure = sum( abs(ghat_1) );
			how_many_initial_iterations=floor(360/in.T);
			a = (in.K - in.p/2) / (how_many_initial_iterations * ghat_measure/in.p);
			if epoch*in.T <=360
				alpha_i = a;
			elseif epoch*in.T <=3600
				hist_miss_ratio = sum(hist_num_of_misses,1) ./hist_tot_requests;
				miss_ratio_past = prctile(hist_miss_ratio',10);
				if hist_miss_ratio(end) <= miss_ratio_past
					% We decrease more
					alpha_i_first = last_coefficient * (epoch-360/in.T )/ (epoch-360/in.T+1);
					alpha_i_second = last_coefficient - (last_coefficient - a/10)/(3600/in.T - epoch+1);
					alpha_i=min(alpha_i_first, alpha_i_second);
					alpha_i=max(alpha_i, a/10);
				else
					alpha_i = last_coefficient - (last_coefficient - a/10)/(3600/in.T - epoch+1);
				end
			else
				iterations_in_10h = 3600*10/in.T;
				alpha_i = last_coefficient * (1- 1/(1+0.1*iterations_in_10h + epoch - 3600/in.T) )^0.501;
			end


		case COEFF_LINEARCUTCAUTIOUSMODERATE10
			a = (in.K - in.p/2) / (in.p * ghat_1_norm);
			if epoch*in.T <=360
				alpha_i = a;
			elseif epoch*in.T <=3600
				hist_miss_ratio = sum(hist_num_of_misses,1) ./hist_tot_requests;
				miss_ratio_past = prctile(hist_miss_ratio',10);
				if hist_miss_ratio(end) <= miss_ratio_past
					% We decrease more
					alpha_i_first = last_coefficient * (epoch )/ (epoch+1);
					alpha_i_second = last_coefficient - (last_coefficient - a/10)/(3600/in.T - epoch+1);
					alpha_i=min(alpha_i_first, alpha_i_second);
					alpha_i=max(alpha_i, a/10);
				else
					alpha_i = last_coefficient - (last_coefficient - a/10)/(3600/in.T - epoch+1);
				end
			else
				iterations_in_10h = 3600*10/in.T;
				alpha_i = last_coefficient * (1- 1/(1+0.1*iterations_in_10h + epoch - 3600/in.T) )^0.501;
			end


		case COEFF_LINEARCUTCAUTIOUS25
			error "copy and paste from LINEARCUTCAUTIOUS10"


		case COEFF_LINEARHALVED10
			error "Copy and paste from LINEARHALVED5"

		case COEFF_LINEARHALVED5
			%{ FIND THE FIRST COEFFICIENT
			how_many_initial_iterations=floor(360/in.T);
			ghat_measure = 0; t=1;
			while ghat_measure==0 && t<=size(hist_ghat,2)
				ghat_measure=sum(abs(hist_ghat(:,t)  ) );
				t++;
			end
			if ghat_measure>0
				a = (in.K - in.p/2) / (how_many_initial_iterations * ghat_measure/in.p);
			else
				a=0;
			end
			%} FIND THE FIRST COEFFICIENT

			if epoch*in.T <=360
				%BOOTSTRAP
				alpha_i = a;
			elseif epoch*in.T <=3600
				%ADAPTIVE
				idx = (hist_tot_requests!=0);
				% We are pessimistic: if we observe no request, we assume miss ratio is 1
				hist_miss_ratio = ones( size(hist_tot_requests) );
				hist_miss_ratio(idx) = (sum(hist_num_of_misses,1)(idx) ) ./hist_tot_requests(idx);
				miss_ratio_past = prctile(hist_miss_ratio',5);
				denominator = 3600/in.T - epoch+1;
				if hist_miss_ratio(end) <= miss_ratio_past
					if denominator==0
						disp denominator; disp in.T; disp epoch;
						error "denominator cannot be zero"
					end
					% We decrease more
					alpha_i_first = last_coefficient /2;
					alpha_i_second = last_coefficient - (last_coefficient - a/10)/denominator;
					alpha_i=min(alpha_i_first, alpha_i_second);
					alpha_i=max(alpha_i, a/10);
				else
					alpha_i = last_coefficient - (last_coefficient - a/10)/denominator;
				end
			else
				iterations_in_10h = 3600*10/in.T;
				denominator = 1+0.1*iterations_in_10h + epoch - 3600/in.T;
				if denominator==0
					disp denominator; disp iterations_in_10h; disp epoch; disp in.T;
					error "denominator cannot be zero"
				end
				alpha_i = last_coefficient * (1- 1/denominator )^0.501;
			end

		case COEFF_LINEARHALVED5REINIT30MIN
			reinit_period = 30*60; % in seconds
			first_iteration = floor(epoch*in.T/reinit_period)+1;
			if epoch < reinit_period/in.T
				epoch_to_consider = epoch;
			else
				epoch_to_consider = mod(epoch*in.T,reinit_period) / in.T +1;
			end
			
			ghat_1 = hist_ghat(:, first_iteration  );
			ghat_measure = sum( abs(ghat_1) );
			how_many_initial_iterations=floor(360/in.T);
			iterations_in_1h = 3600/in.T;
			if ghat_measure==0 || how_many_initial_iterations==0
				disp ghat_measure; disp how_many_initial_iterations;
				error "They cannot be zero"
			end
			a = (in.K - in.p/2) / (how_many_initial_iterations * ghat_measure/in.p);
			if epoch_to_consider <= how_many_initial_iterations
				alpha_i = a;
			elseif epoch_to_consider <= iterations_in_1h
				hist_num_of_misses_to_consider = hist_num_of_misses(:,first_iteration:end);
				hist_tot_requests_to_consider = hist_tot_requests(:,first_iteration:end);
				hist_miss_ratio_to_consider = ...
						sum(hist_num_of_misses_to_consider,1) ./hist_tot_requests_to_consider;
				miss_ratio_past = prctile(hist_miss_ratio_to_consider',5);
				denominator = iterations_in_1h - epoch_to_consider+1;
				if hist_miss_ratio_to_consider(end) <= miss_ratio_past
					% We decrease more
					if denominator<=0
						disp denominator; disp in.T; disp epoch;
						error "denominator must be positive"
					end
					alpha_i_first = last_coefficient /2;
					alpha_i_second = last_coefficient - (last_coefficient - a/10)/denominator;
					alpha_i=min(alpha_i_first, alpha_i_second);
					alpha_i=max(alpha_i, a/10);
				else
					alpha_i = last_coefficient - (last_coefficient - a/10)/denominator;
				end
			else
				error "We should never arrive there"
				iterations_in_10h = 3600*10/in.T;
				denominator = 1+0.1*iterations_in_10h + epoch_to_consider - 3600/in.T;
				alpha_i = last_coefficient * (1- 1/denominator )^0.501;
			end

		case COEFF_LINEARHALVED5REINIT1DAY
			reinit_period = 3600*24; % in seconds
			first_iteration = floor(epoch*in.T/reinit_period)+1;
			if epoch < reinit_period/in.T
				epoch_to_consider = epoch;
			else
				epoch_to_consider = mod(epoch*in.T,reinit_period) / in.T +1;
			end
			
			ghat_1 = hist_ghat(:, first_iteration  );
			ghat_measure = sum( abs(ghat_1) );
			how_many_initial_iterations=floor(360/in.T);
			iterations_in_1h = 3600/in.T;
			if ghat_measure==0 || how_many_initial_iterations==0
				disp ghat_measure; disp how_many_initial_iterations;
				error "They cannot be zero"
			end
			a = (in.K - in.p/2) / (how_many_initial_iterations * ghat_measure/in.p);
			if epoch_to_consider <= how_many_initial_iterations
				alpha_i = a;
			elseif epoch_to_consider <= iterations_in_1h
				hist_num_of_misses_to_consider = hist_num_of_misses(:,first_iteration:end);
				hist_tot_requests_to_consider = hist_tot_requests(:,first_iteration:end);
				hist_miss_ratio_to_consider = ...
						sum(hist_num_of_misses_to_consider,1) ./hist_tot_requests_to_consider;
				miss_ratio_past = prctile(hist_miss_ratio_to_consider',5);
				denominator = iterations_in_1h - epoch_to_consider+1;
				if hist_miss_ratio_to_consider(end) <= miss_ratio_past
					% We decrease more
					if denominator<=0
						disp denominator; disp in.T; disp epoch;
						error "denominator must be positive"
					end
					alpha_i_first = last_coefficient /2;
					alpha_i_second = last_coefficient - (last_coefficient - a/10)/denominator;
					alpha_i=min(alpha_i_first, alpha_i_second);
					alpha_i=max(alpha_i, a/10);
				else
					alpha_i = last_coefficient - (last_coefficient - a/10)/denominator;
				end
			else
				iterations_in_10h = 3600*10/in.T;
				denominator = 1+0.1*iterations_in_10h + epoch_to_consider - 3600/in.T;
				alpha_i = last_coefficient * (1- 1/denominator )^0.501;
			end

		case COEFF_LINEARHALVED5REINIT2H
			reinit_period = 3600*2; % in seconds
			first_iteration = floor(epoch*in.T/reinit_period)+1;
			if epoch < reinit_period/in.T
				epoch_to_consider = epoch;
			else
				epoch_to_consider = mod(epoch*in.T,reinit_period) / in.T +1;
			end
			
			ghat_1 = hist_ghat(:, first_iteration  );
			ghat_measure = sum( abs(ghat_1) );
			how_many_initial_iterations=floor(360/in.T);
			iterations_in_1h = 3600/in.T;
			if ghat_measure==0 || how_many_initial_iterations==0
				disp ghat_measure; disp how_many_initial_iterations;
				error "They cannot be zero"
			end
			a = (in.K - in.p/2) / (how_many_initial_iterations * ghat_measure/in.p);
			if epoch_to_consider <= how_many_initial_iterations
				alpha_i = a;
			elseif epoch_to_consider <= iterations_in_1h
				hist_num_of_misses_to_consider = hist_num_of_misses(:,first_iteration:end);
				hist_tot_requests_to_consider = hist_tot_requests(:,first_iteration:end);
				hist_miss_ratio_to_consider = ...
						sum(hist_num_of_misses_to_consider,1) ./hist_tot_requests_to_consider;
				miss_ratio_past = prctile(hist_miss_ratio_to_consider',5);
				denominator = iterations_in_1h - epoch_to_consider+1;
				if hist_miss_ratio_to_consider(end) <= miss_ratio_past
					% We decrease more
					if denominator<=0
						disp denominator; disp in.T; disp epoch;
						error "denominator must be positive"
					end
					alpha_i_first = last_coefficient /2;
					alpha_i_second = last_coefficient - (last_coefficient - a/10)/denominator;
					alpha_i=min(alpha_i_first, alpha_i_second);
					alpha_i=max(alpha_i, a/10);
				else
					alpha_i = last_coefficient - (last_coefficient - a/10)/denominator;
				end
			else
				iterations_in_10h = 3600*10/in.T;
				denominator = 1+0.1*iterations_in_10h + epoch_to_consider - 3600/in.T;
				alpha_i = last_coefficient * (1- 1/denominator )^0.501;
			end


		case COEFF_LINEARHALVED5REINIT3H
			reinit_period = 3600*3; % in seconds
			first_iteration = floor(epoch*in.T/reinit_period)+1;
			if epoch < reinit_period/in.T
				epoch_to_consider = epoch;
			else
				epoch_to_consider = mod(epoch*in.T,reinit_period) / in.T +1;
			end
			
			ghat_1 = hist_ghat(:, first_iteration  );
			ghat_measure = sum( abs(ghat_1) );
			how_many_initial_iterations=floor(360/in.T);
			iterations_in_1h = 3600/in.T;
			if ghat_measure==0 || how_many_initial_iterations==0
				disp ghat_measure; disp how_many_initial_iterations;
				error "They cannot be zero"
			end
			a = (in.K - in.p/2) / (how_many_initial_iterations * ghat_measure/in.p);
			if epoch_to_consider <= how_many_initial_iterations
				alpha_i = a;
			elseif epoch_to_consider <= iterations_in_1h
				hist_num_of_misses_to_consider = hist_num_of_misses(:,first_iteration:end);
				hist_tot_requests_to_consider = hist_tot_requests(:,first_iteration:end);
				hist_miss_ratio_to_consider = ...
						sum(hist_num_of_misses_to_consider,1) ./hist_tot_requests_to_consider;
				miss_ratio_past = prctile(hist_miss_ratio_to_consider',5);
				denominator = iterations_in_1h - epoch_to_consider+1;
				if hist_miss_ratio_to_consider(end) <= miss_ratio_past
					% We decrease more
					if denominator<=0
						disp denominator; disp in.T; disp epoch;
						error "denominator must be positive"
					end
					alpha_i_first = last_coefficient /2;
					alpha_i_second = last_coefficient - (last_coefficient - a/10)/denominator;
					alpha_i=min(alpha_i_first, alpha_i_second);
					alpha_i=max(alpha_i, a/10);
				else
					alpha_i = last_coefficient - (last_coefficient - a/10)/denominator;
				end
			else
				iterations_in_10h = 3600*10/in.T;
				denominator = 1+0.1*iterations_in_10h + epoch_to_consider - 3600/in.T;
				alpha_i = last_coefficient * (1- 1/denominator )^0.501;
			end


		case COEFF_LINEARLONG
			a = (in.K - in.p/2) / (in.p * ghat_1_norm);
			if epoch*in.T <=3600
				alpha_i = a - (0.9*a/3600 )*(epoch-1)*in.T; 
			else
				iterations_in_100h = 3600*100/in.T;
				a = (in.K - in.p/2)*( ( 1 + 0.1 * iterations_in_100h + 1 )^0.501 ) / (in.p * ghat_1_norm*10);
				alpha_i = a /( ( 1 + 0.1 * iterations_in_100h + (epoch - 3600/in.T +1) )^0.501 );
			end



		otherwise
			error("Coefficients not recognised");
		end%switch
end
