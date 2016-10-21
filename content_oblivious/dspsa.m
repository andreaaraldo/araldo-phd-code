%
function dspsa(in, settings, infile)
	warning("error", "Octave:divide-by-zero");

	%{ SETTINGS
		pkg load statistics
		global severe_debug
		addpath("~/software/araldo-phd-code/general/statistical/");

		if length(in)==0 && length(settings)==0
			load (infile);
			delete(infile);
		end

		variant = [];
		ORIG = 1; OPENCACHE = 3; CSDA = 4; UNIF=5; OPTIMUM=6; DECLARATION=7;
		switch settings.method
			case "dspsa_orig"
				variant = ORIG;
			case "opencache"
				variant = OPENCACHE;
			case "csda"
				variant = CSDA;
			case "unif"
				variant = UNIF;
			case "optimum"
				variant = OPTIMUM;
			case "declaration"
				variant = DECLARATION;
			otherwise
				method
				error("variant not recognised");
		end %switch

		rand("state",settings.seed);randn("state",settings.seed);randp("state",settings.seed);

		p = in.p;
		convergence.required_duration = 1e6;
		convergence.tolerance = 0.1;
		printf_interval = ceil(settings.epochs/1000);

		global PROJECTION_NO, PROJECTION_FIXED, PROJECTION_PROP, PROJECTION_EUCLIDEAN;
	%} SETTINGS
	
	%{ INITIALIZE

		%{COMPUTE THE FIRST theta
		if variant==ORIG || variant==OPENCACHE
			K_prime = in.K-0.5*p;
			theta=repmat( K_prime/p, p,1 );
		elseif variant==CSDA
			K_prime = K;
			theta=repmat( K/p, p,1 );
		elseif variant==UNIF || variant == DECLARATION
			K_prime = K;
			theta=repmat( floor(K/p), p,1 );
		elseif variant == OPTIMUM
			K_prime = K;
			[hit_ratio_improvement, value, in.theta_opt] = optimum_nominal(in, settings, infile);
			theta = in.theta_opt;
		end
		%}COMPUTE THE FIRST theta

		%{ HANDLE ON OFF state
			% Initialize in.ONobjects
			% The in.ONobjects has a 1 in correspondence to active objects
			if in.ONtime < 1 && in.ONtime > 0
				in.ONobjects = (rand(in.p, max(in.ctlg) )<= in.ONtime );

				in.p_on_off = in.T*1.0/ (in.ONtime*in.ONOFFspan*3600*24);
				in.p_off_on = in.T*1.0/ ( (1- in.ONtime)*in.ONOFFspan*3600*24);
			elseif in.ONtime > 1 || in.ONtime <= 0
				error "in.ONtime can be neither larger than 1 nor 0"
			end
		%} HANDLE ON OFF state

	
		how_many_step_updates = 1;

		if variant == CSDA
			theta_old = miss_ratio_old = theta_previous = Delta = zeros(in.p, 1);
		end%if

		convergence.duration = 0;

		% Historical num of misses. One row per each CP, one column per each epoch
		hist_nominal_misses = hist_tot_requests = [];

		in.hist_theta = hist_ghat = hist_a = hist_thet = hist_updates = ...
			hist_activated_objects = hist_trash = hist_unused = ...
			hist_deactivated_objects = hist_downloads_to_cache = [];

		in.last_cdf_vector = cdf = in.last_test_theta = zeros(in.p,1);
	%} INITIALIZE

	for i=1:settings.epochs
		if mod(i,printf_interval)==0
			printf("%g/%g=%d%%; ",i,settings.epochs, i*100/settings.epochs);
		end

		% Number of objects downloaded to the cache in this iteration.
		% These are the objects that are requested but are not present in the 
		% cache at the moment of request
		downloads_to_cache_in_iteration = zeros(in.p,1);

		
		if variant == ORIG || variant == OPENCACHE
		%{DELTA GENERATION
			Delta = round(unidrnd(2,p/2,1) - 1.5);
			ordering = randperm(p/2);
			Delta2 = -Delta(ordering);
			Delta = [Delta; Delta2];
		%}DELTA GENERATION
		end%if

		%{ BUILD TEST CONFIGURATIONS
		if variant == ORIG || variant == OPENCACHE
			%theta = anti_integer(theta, p, in.K, sigma=0.0001);
			test_theta = [];
			pi_ = floor(theta) + 1/2;
			theta_minus = pi_ - 0.5*Delta;
			theta_plus = pi_ + 0.5*Delta;
			test_theta = [theta_minus, theta_plus];
		elseif variant == CSDA
			test_theta = round(theta);
		elseif variant==UNIF || variant==DECLARATION
			test_theta = theta;
		elseif variant == OPTIMUM
			test_theta = in.theta_opt;
		endif

			%{CHECK CONFIG
			if severe_debug && any( sum(test_theta, 1)>in.K ) 
					theta
					sum_of_theta=sum(theta)
					test_theta
					error(sprintf("test_theta is incorrect in iteration %d",i) )
			endif
			%}CHECK CONFIG
		%} BUILD TEST CONFIGURATIONS

		%{ RUN TESTS
		% one row per each CP, one columns per each test
		tot_requests = nominal_misses = vec_y = miss_ratio = [];
		for test = 1:size(test_theta, 2)

			current_test_theta = test_theta(:,test);

			%{ COMPUTE_NUM_OF_MISSES
			% We divide lambdatau by the number of tests, because, for example if tests are 2,
			% at each epoch for half of the time we evaluate 
			% test_c(:,1) and for the other half test_c(:,2). Therefore the frequency is halved

			if variant==DECLARATION
				error "not supported anymore"
			elseif in.ONtime==1
				[current_nominal_misses, current_tot_requests, F, cdf, downloads_to_cache] = ...
					compute_num_of_misses_gross(in, current_test_theta, in.T/size(test_theta, 2));
				downloads_to_cache_in_iteration = downloads_to_cache_in_iteration .+ downloads_to_cache;

			else #in.ONtime<1
				[current_nominal_misses, current_tot_requests, F] = ...
					compute_num_of_misses_fine(in, current_test_theta, in.T/size(test_theta, 2) );
			end
			nominal_misses = [nominal_misses, current_nominal_misses];
			%} COMPUTE_NUM_OF_MISSES

			tot_requests = [tot_requests, current_tot_requests]; % One scalar cell per each test
			
			%{ COMPUTE vec_y or similar
			if variant == ORIG || variant == OPENCACHE
				
				if current_tot_requests != 0
					current_vec_y = current_nominal_misses / current_tot_requests;
				else
					current_vec_y = zeros(in.p,1);
				end
				vec_y= [vec_y, current_vec_y];
			elseif variant == CSDA
				current_miss_ratio = zeros(in.p, 1);
				idx_selector = (current_tot_requests .* F != zeros(in.p,1) );
				current_miss_ratio(idx_selector) = ...
					current_nominal_misses(idx_selector)...
					 ./ (current_tot_requests.* F)(idx_selector)  ;
				miss_ratio = [miss_ratio, current_miss_ratio];
			
				vec_y = F .* miss_ratio ;
				vec_y_old = F .* miss_ratio_old;
			% else if variant==UNIF || variant==DECLARATION
			%	We do not need to do anything
			end%if
			%} COMPUTE vec_y

			if severe_debug
				if any( (cdf>0) .* (current_test_theta==0) )
					cdf
					current_test_theta
					error "Found a CP which has zero slots but positive cdf (i.e. positive hit ratio). This is an error"
				end
			end

			in.last_test_theta = current_test_theta;
			in.last_cdf_vector=cdf;
		end%test
		%} RUN TESTS

		if severe_debug && sum(nominal_misses)>tot_requests
			nominal_misses
			tot_requests
			error "Error: misses are more than the requests: weird"
		end

		%{ HISTORICAL DATA
		if settings.ON_hist_trash
			unused = trash = 0;
			in.theta_opt = compute_optimum(in);
			for test = 1:size(test_theta, 2)
				current_test_theta = test_theta(:,test);

				cached_estimated_ranks = in.estimated_rank;
				trash=0; % If knowledge is infinite the trash is zero, otherwise...
				if in.know < Inf
					for j=1:in.p
						cached_estimated_ranks(j,current_test_theta(j)+1 : end) = 0;
						trash += sum ( cached_estimated_ranks(j,:)>in.theta_opt(j) ) ;
					end
				end
				unused += in.K - sum(sum(cached_estimated_ranks>0) );
			end

			unused = unused / size(test_theta, 2);
			trash = trash / size(test_theta, 2);
			hist_unused = [hist_unused, unused];
			hist_trash = [hist_trash, trash];
		end

		hist_nominal_misses = [hist_nominal_misses, sum(nominal_misses,2) ];
		hist_tot_requests = [hist_tot_requests, sum(tot_requests,2) ];
		hist_downloads_to_cache = [hist_downloads_to_cache, downloads_to_cache_in_iteration];
		%} HISTORICAL DATA

		%{ COMPUTE ghat
			if variant==ORIG
				delta_y = sum(vec_y(:,2))  -sum(vec_y(:,1) ); 
				ghat = delta_y * Delta;

			elseif variant==OPENCACHE
				delta_vec_y = vec_y(:,2) .- vec_y(:,1);
				ghat = delta_vec_y .* Delta - (1.0/p) * (delta_vec_y' * Delta) .* ones(p,1);

			elseif variant==CSDA
					d_vec_y = (vec_y - vec_y_old) ./ (theta-theta_old);
					ghat = d_vec_y - (1.0/p) * (d_vec_y' * ones(in.p,1) ) .* ones(in.p,1);

			elseif variant==UNIF || variant==DECLARATION || variant==OPTIMUM
					ghat = zeros(in.p, 1);
			end

			ghat = normalize_ghat(ghat, settings.normalize);
			ghat = ghat * settings.boost;
			hist_ghat = [hist_ghat, ghat];
			%{CHECK
			if severe_debug
				if any(isnan(vec_y) )
					vec_y
					current_tot_requests
					error("Some element of vec_y is NaN. This is an error.")
				end


				if any(isnan(ghat) )
					error("Some element of ghat is NaN. This is an error.")
				end
			end
			%}CHECK
		%} COMPUTE ghat

		%{COEFFICIENT
		last_coefficient = []; if i>1; last_coefficient=hist_a(end); end;
		alpha_i =  compute_coefficient(in, settings, i, hist_nominal_misses, hist_tot_requests,...
			last_coefficient,how_many_step_updates, hist_ghat);
		if length(hist_a)>0 && hist_a(end) != alpha_i
			how_many_step_updates++;
		end
		hist_a = [hist_a, alpha_i];
		%}COEFFICIENT

		%{ COMPUTE theta
		if variant!=DECLARATION
			theta = theta - alpha_i * ghat;
		else %declaration
			error "not supported as for now"
			lambdatau_reconstruct = zeros(size(in.lambdatau) );
			for j=1:in.p
				tot_reqs = sum(requests_per_object(j,:));
				if tot_reqs != 0
					prob_obs = requests_per_object(j,:) / tot_reqs;
				else
					prob_obs = zeros(size(requests_per_object(j,:)) );
				end
				lambdatau_reconstruct(j,:) = zipf_fitting(prob_obs) * F(j);
			end
			theta = compute_optimum(in.p, lambdatau_reconstruct, in.K);
		end

		if any(theta<0) && settings.projection!=PROJECTION_NO

			%{ COMPUTE FRACTION
			switch settings.projection
				case PROJECTION_EUCLIDEAN
					u = sort(theta,"descend");
					partial_sum=previous_z=z=j=0;
					do
						j++;
						partial_sum += u(j);
						previous_z = z;
						z = (1/j)*(K_prime - partial_sum);
					until u(j)+z < 0 || j==in.p
					if (u(j)+z < 0) z=previous_z; end;
					theta = max(theta+repmat(z,in.p,1), zeros(in.p,1) );

				case PROJECTION_FIXED
					todistribute = sum( theta(theta<0) ) ;
					fraction = zeros(in.p, 1);
					fraction(theta>=0) = 1 / sum(theta>=0 );
					correction = todistribute * fraction;
					theta = theta .+ correction;

				case PROJECTION_PROP
					todistribute = sum( theta(theta<0) ) ;
					fraction = zeros(in.p, 1);
					fraction(theta>=0) = theta(theta>=0) / sum(theta(theta>=0) );
					correction = todistribute * fraction;
					theta = theta .+ correction;

				otherwise
					error("Projection erroneous");
			end
			%} COMPUTE FRACTION
		end
		%} COMPUTE theta

		%{ UPDATE in.ONobjects
		if in.ONtime<1
			objects_to_switch_off_large = rand(size(in.ONobjects) ) <= in.p_on_off;
			temp = in.ONobjects + objects_to_switch_off_large;
			objects_to_switch_off = (temp == 2);

			objects_to_switch_on_large = rand(size(in.ONobjects) ) <= in.p_off_on;
			temp = in.ONobjects - objects_to_switch_on_large;
			objects_to_switch_on = (temp == -1);
			in.ONobjects = in.ONobjects - objects_to_switch_off+ objects_to_switch_on;

			hist_activated_objects = [hist_activated_objects, sum(sum(objects_to_switch_on) )];
			hist_deactivated_objects = [hist_deactivated_objects, sum(sum(objects_to_switch_off) )];

			if severe_debug
				if any(objects_to_switch_on+objects_to_switch_off>1)
					error "error in updating in.ONobjects"
				end
			end
		end
		%} UPDATE in.ONobjects

		in.hist_theta = [in.hist_theta, theta];

		if variant == CSDA
			idx_selection = round(theta) != round(theta_previous);
			theta_old( idx_selection ) = round( theta_previous(idx_selection) );
			miss_ratio_old( idx_selection ) = miss_ratio( idx_selection );
		end

		%{CHECK
		if severe_debug
			if any(isnan(theta) ) || any(isnan(theta) )
				error("Some element of theta is NaN. This is an error.")
			end

			if variant!=UNIF && variant!=OPTIMUM && variant!=OPTIMUM && variant!=DECLARATION && ...
				sum(Delta) != 0 && sum(ghat)!=0

				Delta
				delta_vc
				error("Zero-sum property does not hold")
			end

			if abs( sum(theta) - K_prime ) >1e-3
				error_is = K_prime-sum(theta)
				this_is_theta=theta'
				sum(theta)
				error("theta is invalid")
			end	
		end
		%}CHECK



	end%for iterations

	if settings.save_mdat_file

		save("-binary", settings.outfile);
		disp (sprintf("\n%s written", settings.outfile) );
	end

	printf("\nsuccess\n");
end%function
