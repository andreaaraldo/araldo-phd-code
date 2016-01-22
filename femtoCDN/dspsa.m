%Modified version of [1]

% [1] Wang, Spall - "Discrete simultaneous perturbation stochastic approximation on loss function with noisy measurements"	
function dspsa(in, settings, infile)

	%{ SETTINGS
		global severe_debug

		if length(in)==0 && length(settings)==0
			load (infile);
			delete(infile);
		end

		variant = [];
		ORIG = 1; OPENCACHE = 3; CSDA = 4;
		switch settings.method
			case "dspsa_orig"
				variant = ORIG;

			case "opencache"
				variant = OPENCACHE;

			case "csda"
				variant = CSDA;

			otherwise
				method
				error("variant not recognised");
		end %switch

		rand("seed",settings.seed);
		p = in.p;
		convergence.required_duration = 1e6;
		convergence.tolerance = 0.1;
		printf_interval = ceil(settings.epochs/100);
	%} SETTINGS
	
	%{ INITIALIZE
	theta=repmat( (in.K-0.5*p/2) *1.0/p, p,1 ); %virtual configuration


	if variant == CSDA
		theta_old = miss_ratio_old = theta_previous = Delta = zeros(in.p, 1);
	end%if

	theta_opt = in.req_proportion' * in.K;
	convergence.duration = 0;	

	% Historical num of misses. One row per each CP, one column per each epoch
	hist_num_of_misses = hist_tot_requests = [];

	hist_theta = [];
	hist_ghat = [] ;
	hist_a = [];
	%} INITIALIZE

	for i=1:settings.epochs
		if mod(i,printf_interval)==0
			printf("%g/%g=%d%%; ",i,settings.epochs, i*100/settings.epochs);
		end

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
			test_theta = [];
			pi_ = floor(theta) + 1/2;
			theta_minus = pi_ - 0.5*Delta;
			theta_plus = pi_ + 0.5*Delta;
			%{ CORRECTION
			while sum(theta_plus)> in.K || sum(theta_plus)> in.K
				theta = (1-0.0001) * theta;
				pi_ = floor(theta) + 1/2;
				theta_minus = pi_ - 0.5*Delta;
				theta_plus = pi_ + 0.5*Delta;
			end
			%} CORRECTION

			test_theta = [theta_minus, theta_plus];
		elseif variant == CSDA
			test_theta = round(theta);
			%{ CORRECTION
			while sum(test_theta)> in.K
				theta = (1-0.0001) * theta;
				test_theta = round(theta);
			end
			%} CORRECTION
		endif
			%{CHECK CONFIG
			if severe_debug && any( sum(test_theta, 1)>in.K )
					theta
					test_theta
					error("test_theta is uncorrect")
			endif
			%}CHECK CONFIG
		%} BUILD TEST CONFIGURATIONS

		%{ RUN TESTS
		% one row per each CP, one columns per each test
		tot_requests = num_of_misses = vec_y = miss_ratio = [];
		for test = 1:size(test_theta, 2)
			current_theta = test_theta(:,test);

			% We divide lambdatau by 2, because at each epoch for half of the time we evaluate 
			% test_c(:,1) and for the other half test_c(:,2). Therefore the frequency is halved
			inlambdataus_is = sum(in.lambdatau,2)'
			[current_num_of_misses, current_tot_requests, F] = ...
				compute_num_of_misses(in, current_theta, in.lambdatau*1.0/size(test_theta, 2));
			num_of_misses = [num_of_misses, current_num_of_misses];

			tot_requests = [tot_requests, current_tot_requests];
			
			%{ COMPUTE vec_y or similar
			if variant == ORIG || variant == OPENCACHE
				current_vec_y = zeros(in.p,1);
				idx_selector = current_tot_requests != 0; 
				current_vec_y(idx_selector) = ...
					current_num_of_misses(idx_selector) ./ ...
					current_tot_requests(idx_selector);
				vec_y= [vec_y, current_vec_y];
			elseif variant == CSDA
				current_miss_ratio = zeros(in.p, 1);
				idx_selector = (current_tot_requests .* F != zeros(in.p,1) );
				current_miss_ratio(idx_selector) = ...
					current_num_of_misses(idx_selector)...
					 ./ (current_tot_requests.* F)(idx_selector)  ;
				miss_ratio = [miss_ratio, current_miss_ratio];
			
				vec_y = F .* miss_ratio ;
				vec_y_old = F .* miss_ratio_old;
			end%if
			%} COMPUTE vec_y
		end%test
		%} RUN TESTS

		% Historical data
		hist_num_of_misses = [hist_num_of_misses, sum(num_of_misses,2) ];
		hist_tot_requests = [hist_tot_requests, sum(tot_requests,2) ];

		%{ COMPUTE ghat
		ghat_1_norm = [];
		switch variant
			case ORIG
				delta_y = sum(vec_y(:,2))  -sum(vec_y(:,1) ); 
				ghat = delta_y * Delta;

			case OPENCACHE
				delta_vec_y = vec_y(:,2) .- vec_y(:,1);
				ghat = delta_vec_y .* Delta - (1.0/p) * (delta_vec_y' * Delta) .* ones(p,1);
				vec_y_is = [vec_y'; delta_vec_y']

			case CSDA
				d_vec_y = (vec_y - vec_y_old) ./ (theta-theta_old);
				ghat = d_vec_y - (1.0/p) * (d_vec_y' * ones(in.p,1) ) .* ones(in.p,1);
				
		end % switch
		if i==1; in.ghat_1_norm=norm(ghat); end

		ghat = normalize_ghat(ghat, settings.normalize);
		ghat = ghat * settings.boost;
		hist_ghat = [hist_ghat, ghat];
		%{CHECK
		if severe_debug
			if any(isnan(vec_y) )
				error("Some element of ghat is NaN. This is an error.")
			end


			if any(isnan(ghat) )
				error("Some element of ghat is NaN. This is an error.")
			end
		end
		%}CHECK

		%} COMPUTE ghat

		alpha_i =  compute_coefficient(in, settings, i);
		theta = theta - alpha_i * ghat;

		while settings.balancer && any(theta<0)
			todistribute = sum( theta(theta<0) ) ;
			fraction = zeros(in.p, 1);
			%fraction(theta>=0) = theta(theta>=0) / sum(theta(theta>=0) );
			fraction(theta>=0) = 1 / sum(theta>=0 );
			theta = theta .+ todistribute .* fraction;
			theta(theta<0) = 0;
		end


		hist_theta = [hist_theta, theta];
		hist_a = [hist_a, alpha_i];

		if variant == CSDA
			idx_selection = round(theta) != round(theta_previous);
			theta_old( idx_selection ) = round( theta_previous(idx_selection) );
			miss_ratio_old( idx_selection ) = miss_ratio( idx_selection );
		end

		%{CHECK
		if severe_debug
			if any(isnan(theta) )
				error("Some element of theta is NaN. This is an error.")
			end

			if sum(Delta) != 0 && sum(ghat)!=0
				Delta
				delta_vc
				error("Zero-sum property does not hold")
			end
		end
		%}CHECK

		%{ CONVERGENCE
		err = norm(theta-theta_opt)/norm(theta_opt);
		if err <= convergence.tolerance
			convergence.duration ++;
		else
			convergence.duration = 0;
		end

		if convergence.duration == convergence.required_duration
			break;
		end
		%} CONVERGENCE


	end%for


	if settings.save_mdat_file
		%lambdatau can be hige if the catalog is big. It is better not to save it
		in.lambdatau = [];

		save("-binary", settings.outfile);
		disp (sprintf("%s written", settings.outfile) );
	end

%	hist_cum_hit(settings.epochs)
	printf("\nsuccess\n");
end%function
