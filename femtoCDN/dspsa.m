%Modified version of [1]

% [1] Wang, Spall - "Discrete simultaneous perturbation stochastic approximation on loss function with noisy measurements"	
function dspsa(in, settings)
	% SETTINGS
	global severe_debug
	enhanced = false;
	N = in.N;
	vc=repmat( in.K*1.0/N, N,1 ); %virtual configuration


	for i=1:settings.epochs
		%{DELTA GENERATION
			Delta = round(unidrnd(2,N/2,1) - 1.5);
			ordering = randperm(N/2);
			Delta2 = -Delta(ordering);
			Delta = [Delta; Delta2];
		%}DELTA GENERATION
		pi_ = round(vc);
		test_c = pi_ + Delta;
		test_c = [test_c, pi_ - Delta];
		if enhanced
			test_c = [test_c, pi_];
		end

		f = m = [];
		for test = 1:length(test_c)
			c = test_c(:,test);

			% We divide lambda by 2, because at each epoch for half of the time we evaluate 
			% test_c(:,1) and for the other half test_c(:,2). Therefore the frequency is halved
			[cm, cf] = compute_miss(in, c, in.lambda/2);
			m = [m, cm];
			f = [f, cf];
		end%test

		if !enhanced
			M = sum(m, 1) ./ sum(f, 1); % miss stream for each epoch
			delta_vc = ( M(1)-M(2) ) * Delta; % gradient, g in [1]
			vc = vc - delta_vc;
		else
			improvement = loose = zeros(N,1);

			% With Delta>0 we are selecting the CPs that received th additional slot in the 
			% first test and who lost a slot in the second test. 
			% With Delta<0 we select the rest
			improvement(Delta>0 ) = m(Delta>0, 3) - m(Delta>0, 1);
			loose(Delta>0) = m(Delta>0, 2) - m(Delta>0, 3);
			improvement(Delta<0 ) = m(Delta<0, 3) - m(Delta<0, 2);
			loose(Delta<0) = m(Delta<0, 1) - m(Delta<0, 3);

			permutations = perms(Delta)';
			winning_permutation = [];
			gain = 0;
			for i=1:size(permutations)
				permutation = permutations(:,i);
				this_gain = sum(improvement(permutation>0) ) - sum(loose(permutation<0) );
				if this_gain > gain
					winning_permutation = permutation;
					gain = this_gain;
				end
			end
			if gain>0
				vc = vc + winning_permutation;
			% else no changes
			end
		end

		real_c = round(vc);
		disp(real_c(2)/sum(real_c) )

		%{CHECK
			if sum(Delta) != 0 && sum(delta_vc)!=0
				Delta
				delta_vc
				error("Zero-sum property does not hold")
			end

			if sum( test_c(:,1) ) > in.K || sum( test_c(:,2) ) > in.K
				test_c
				error("test_c is uncorrect")
			end
		%}CHECK

	end%for

end%function
