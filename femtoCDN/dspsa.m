%Modified version of [1]

% [1] Wang, Spall - "Discrete simultaneous perturbation stochastic approximation on loss function with noisy measurements"	
function dspsa(in, settings, infile)
	if length(in)==0 && length(settings)==0
		load (infile);
		delete(infile);
	end


	% SETTINGS
	global severe_debug
	enhanced = settings.enhanced;

	N = in.N;
	vc=repmat( in.K*1.0/N, N,1 ); %virtual configuration

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

		if severe_debug; vc_before_correction = vc; end

		vc = correct_vc(vc, in);
		pi_ = round(vc);
		test_c = pi_ + Delta;
		test_c = [test_c, pi_ - Delta];

		%{CHECK CONFIG
		if severe_debug && any( sum(test_c, 1)>in.K )
				vc
				vc_before_correction
				pi_
				test_c
				slots_of_pi_ = sum(pi_)
				slot_of_C = sum(c)
				slots_of_test_c = sum(test_c, 1)
				error("test_c is uncorrect")
		end
		%}CHECK CONFIG

		if(enhanced)
			test_c = [test_c, pi_];
		end

		% fraction of time dedicated to each test;
		test_duration = repmat(1/size(test_c,2), 1, size(test_c,2) );
		
		% f: tot requests; m: number of misses
		f = m = []; % one row per each CP, one columns per each test
		for test = 1:size(test_c,2)
			c = test_c(:,test);

			% We divide lambdatau by 2, because at each epoch for half of the time we evaluate 
			% test_c(:,1) and for the other half test_c(:,2). Therefore the frequency is halved
			[cm, cf] = compute_miss(in, c, in.lambdatau * test_duration(test) );
			m = [m, cm];
			f = [f, cf];
		end%test

		% Historical data
		hist_m = [hist_m, sum(m,2) ]; hist_f = [hist_f, sum(f,2) ];

		if !enhanced
			M = sum(m, 1) ./ sum(f, 1); % miss ratio per each epoch
			delta_vc = ( M(1)-M(2) ) * Delta; % gradient, g in [1]

			if settings.normalize
				delta_vc = normalize_delta_vc(delta_vc);
			end

			alpha_i =  compute_coefficient(settings, i);
			vc = vc - alpha_i * delta_vc;
			hist_delta_vc = [hist_delta_vc, delta_vc];
		else
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


			delta_vc = compute_enhanced_delta_vc(improvement, loose);
			vc = vc + delta_vc;
			hist_delta_vc = [hist_delta_vc, delta_vc];
		end

		%{CHECK
		if severe_debug
			if sum(Delta) != 0 && sum(delta_vc)!=0
				Delta
				delta_vc
				error("Zero-sum property does not hold")
			end

			if enhanced && settings.normalize
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
