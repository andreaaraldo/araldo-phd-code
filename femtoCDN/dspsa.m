%Modified version of [1]

% [1] Wang, Spall - "Discrete simultaneous perturbation stochastic approximation on loss function with noisy measurements"	
function dspsa(in, settings, infile)
	if length(in)==0 && length(settings)==0
		load (infile);
		delete(infile);
	end

	variant = [];
	ORIG = 1; ENHANCED = 2; SUM = 3; RED=4;
	switch settings.method
		case "dspsa_orig"
			variant = ORIG;

		case "dspsa_enhanced"
			variant = ENHANCED;

		case "dspsa_sum"
			variant = SUM;

		case "dspsa_red" % reduction
			variant = RED;

		otherwise
			method
			error("variant not recognised");
	end %switch



	% SETTINGS
	global severe_debug

	N = in.N;

	%{ INIT
		unit = [];
		if variant == ORIG || variant == ENHANCED
			unit = in.K*1.0/N;
		elseif variant == SUM || variant == RED
			unit = (in.K - 0.5*N)/N;		
		end
		vc=repmat( unit, N,1 ); %virtual configuration
	%} INIT

	hist_m = []; % Historical miss stream. One row per each CP, one column per each epoch
	hist_f = []; % historical tot_requests
	hist_vc = vc;
	hist_delta_vc = zeros(N,1) ;

	for i=1:settings.epochs
		printf("%g/%g; ",i,settings.epochs);

		%{DELTA GENERATION
			Delta = round(unidrnd(2,N/2,1) - 1.5);
			ordering = randperm(N/2);
			Delta2 = -Delta(ordering);
			Delta = [Delta; Delta2];
		%}DELTA GENERATION


		%{ BUILD TEST CONFIGURATIONS
			test_c = [];
			if variant==ORIG || variant == ENHANCED
				if severe_debug; vc_before_correction = vc; end
				vc = correct_vc(vc, in);
				pi_ = round(vc);
				test_c = [pi_ + Delta, pi_ - Delta];

				if variant == ENHANCED
					test_c = [test_c, pi_];
				end

			elseif variant == SUM || variant == RED
				pi_ = floor(vc) + 1/2;
				c_plus = pi_ + 0.5*Delta;
				c_minus = pi_ - 0.5*Delta;
				test_c = [c_plus, c_minus];
			end
			%{CHECK CONFIG
			if severe_debug && any( sum(test_c, 1)>in.K )
					vc
					pi_
					test_c
					slots_of_pi_ = sum(pi_)
					slots_of_test_c = sum(test_c, 1)
					error("test_c is uncorrect")
			end
			%}CHECK CONFIG
		%} BUILD TEST CONFIGURATIONS


		% fraction of time dedicated to each test;
		test_duration = repmat(1/size(test_c,2), 1, size(test_c,2) );

		%{ RUN TESTS		
		% f: tot requests; m: number of misses
		f = m = []; % one row per each CP, one columns per each test
		for test = 1:size(test_c,2)
			c = test_c(:,test);

			% We divide lambdatau by 2, because at each epoch for half of the time we evaluate 
			% test_c(:,1) and for the other half test_c(:,2). Therefore the frequency is halved
			[cm, cf] = compute_miss(in, c, in.lambdatau * test_duration(test) );
			m = [m, cm]; 	%each column of m is related to a test. Each cell of that column 
							% is the number of misses during that test

			f = [f, cf];	%f: number of requests, structured as m
		end%test
		%} RUN TESTS

		% Historical data
		hist_m = [hist_m, sum(m,2) ]; hist_f = [hist_f, sum(f,2) ];

		%{ COMPUTE delta_vc
		switch variant
			case SUM
				tot_req = repmat(sum(f, 1), N, 1);
				mi = m ./ tot_req; % miss intensity: one column per epoch, one row per CP
				pre_delta_vc = ( mi(:,1) -  mi(:,2) ) .* Delta;
				delta_vc = pre_delta_vc .- repmat(sum(pre_delta_vc)/N, N, 1);

			case RED
				tot_req = repmat(sum(f, 1), N, 1);
				mi = m ./ tot_req; % miss intensity: one column per epoch, one row per CP
				%{BUILD THE CUMULATIVE delta_vc
				cumulative_delta_vc = zeros(N,1);
				for j=1:N
					%{ BUILD THE REDUCTION
						cut_mi = mi;
						cut_mi(j,:) = zeros(1,2);
						mu = mi(j,:) ./ (N-1);
						mu = repmat(mu,N,1);
						L = mi .+ mu;
						L(j,:) = zeros(1,2);
					%} BUILD THE REDUCTION
					reduced_delta_vc = ( L(:,1) - L(:,2) ) ./ Delta;
					reduced_delta_vc(j) =  -1 * sum(reduced_delta_vc) ;
					cumulative_delta_vc += reduced_delta_vc;
				end
				delta_vc = cumulative_delta_vc / N;
				%}BUILD THE CUMULATIVE delta_vc

			case ORIG
				M = sum(m, 1) ./ sum(f, 1); % miss ratio per each epoch
				delta_vc = ( M(1)-M(2) ) * Delta; % gradient, g in [1]

			case ENHANCED
				improvement = loose = zeros(N,1);

				% With Delta>0 we are selecting the CPs that received th additional slot in the 
				% first test and who lost a slot in the second test. 
				% With Delta<0 we select the rest
				improvement(Delta>0 ) = ...
					m(Delta>0, 3) / sum(f(Delta>0, 3) ) - m(Delta>0, 1) / sum( f(Delta>0, 1) );
				loose(Delta>0) = ...
					m(Delta>0, 2) / sum(f(Delta>0, 2) ) - m(Delta>0, 3) / sum(f(Delta>0, 3) );
				improvement(Delta<0 ) = ...
					m(Delta<0, 3) / sum(f(Delta<0, 3) ) - m(Delta<0, 2) / sum(f(Delta<0, 2) );
				loose(Delta<0) = ...
					m(Delta<0, 1) / sum(f(Delta<0, 1) ) - m(Delta<0, 3) / sum(f(Delta<0, 3) );


				delta_vc = -1 * compute_enhanced_delta_vc(improvement, loose);

		end % switch

		if settings.normalize
			delta_vc = normalize_delta_vc(delta_vc);
		end

		%} COMPUTE delta_vc

		alpha_i =  compute_coefficient(settings, i);
		vc = vc - alpha_i * delta_vc;
		hist_delta_vc = [hist_delta_vc, delta_vc];

		%{CHECK
		if severe_debug
			if sum(Delta) != 0 && sum(delta_vc)!=0
				Delta
				delta_vc
				error("Zero-sum property does not hold")
			end

			if variant == ENHANCED && settings.normalize
				error("You cannot normilize in the enhanced version");
			end
		end
		%}CHECK
		hist_vc = [hist_vc, vc];



	end%for

	[hist_allocation, hist_cum_observed_req, hist_cum_hit] = compute_metrics(...
		in, settings, hist_vc, hist_m, hist_f);

	if settings.save_mdat_file
		save(settings.outfile);
		disp (sprintf("%s written", settings.outfile) );
	end
	printf("\nsuccess\n");
end%function
