%Modified version of [1]

% [1] Wang, Spall - "Discrete simultaneous perturbation stochastic approximation on loss function with noisy measurements"	
function dspsa(in, settings, infile)

	% SETTINGS
	global severe_debug

	if length(in)==0 && length(settings)==0
		load (infile);
		delete(infile);
	end

	variant = [];
	ORIG = 1; OPENCACHE = 3;
	switch settings.method
		case "dspsa_orig"
			variant = ORIG;

		case "opencache"
			variant = OPENCACHE;

		otherwise
			method
			error("variant not recognised");
	end %switch



	% SETTINGS
	global severe_debug
	rand("seed",settings.seed);
	p = in.p;
	theta_opt = in.req_proportion' * in.K;
	
	%{ GENERATE THE INITIAL CONFIG
	theta=repmat( (in.K-0.5*p) *1.0/p, p,1 ); %virtual configuration
	%{
	while sum(theta) > in.K
		theta(rand(1,1,[1:p]) )	--
	end%while
	while sum(theta) < in.K
		theta(rand(1,1,[1:p]) )	++
	end%while
	%}
	%} GENERATE THE INITIAL CONFIG


	% Historical num of misses. One row per each CP, one column per each epoch
	hist_num_of_misses = []; 

	hist_tot_requests = []; % historical tot_requests
	hist_theta = theta;
	hist_ghat = zeros(p,1) ;

	for i=1:settings.epochs
		printf("%g/%g; ",i,settings.epochs);

		%{DELTA GENERATION
			Delta = round(unidrnd(2,p/2,1) - 1.5);
			ordering = randperm(p/2);
			Delta2 = -Delta(ordering);
			Delta = [Delta; Delta2];
		%}DELTA GENERATION


		%{ BUILD TEST CONFIGURATIONS
			test_theta = [];
			pi_ = floor(theta) + 1/2;
			theta_minus = pi_ - 0.5*Delta;
			theta_plus = pi_ + 0.5*Delta;
			test_theta = [theta_minus, theta_plus];
			%{CHECK CONFIG
			if severe_debug && any( sum(test_theta, 1)>in.K )
					theta
					pi_
					test_theta
					error("test_theta is uncorrect")
			end
			%}CHECK CONFIG
		%} BUILD TEST CONFIGURATIONS


		%{ RUN TESTS
		% one row per each CP, one columns per each test
		tot_requests = num_of_misses = vec_y = [];
		for test = 1:2
			current_theta = test_theta(:,test);

			% We divide lambdatau by 2, because at each epoch for half of the time we evaluate 
			% test_c(:,1) and for the other half test_c(:,2). Therefore the frequency is halved
			[current_num_of_misses, current_tot_requests] = ...
				compute_num_of_misses(in, current_theta, in.lambdatau/2.0);
			num_of_misses = [num_of_misses, current_num_of_misses];
			tot_requests = [tot_requests, current_tot_requests];
			vec_y = [vec_y, current_num_of_misses ./ current_tot_requests];
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
				ghat = delta_vec_y .* Delta - (1.0/p) * (delta_vec_y' * Delta) * ones(p,1);
		end % switch
		if i==1; in.ghat_1_norm=norm(ghat); end

		ghat = normalize_ghat(ghat, settings.normalize);
		ghat = ghat * settings.boost;
		hist_ghat = [hist_ghat, ghat];
		%} COMPUTE ghat

		alpha_i =  compute_coefficient(in, settings, i);
		theta = theta - alpha_i * ghat;
		hist_theta = [hist_theta, theta];

		%{CHECK
		if severe_debug
			if sum(Delta) != 0 && sum(ghat)!=0
				Delta
				delta_vc
				error("Zero-sum property does not hold")
			end
		end
		%}CHECK



	end%for

	[hist_allocation, hist_cum_observed_req, hist_cum_hit] = compute_metrics(...
		in, settings, hist_theta, hist_num_of_misses, hist_tot_requests);

	if settings.save_mdat_file
		save("-binary", settings.outfile);
		disp (sprintf("%s written", settings.outfile) );
	end

	hist_difference = ( hist_theta - repmat(theta_opt,1, size(hist_theta,2)) ) / in.K;
	hist_MSE = meansq( hist_difference , 1 );
%	hist_cum_hit(settings.epochs)
	printf("\nsuccess\n");
end%function
