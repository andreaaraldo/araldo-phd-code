function cumulative_steepest_descent(in, settings)
	% SETTINGS
	boost =  false;
	only_plausible_updates = false;
	global severe_debug

	N = in.N; %num CPs

	%{INITIALIZATION
		Lc = LM = zeros(N,1);
		vc=repmat( in.K*1.0/N, N,1 ); %virtual configuration
		hist_m = []; % Historical miss stream. One row per each CP, one column per each epoch
		hist_f = []; % historical tot_requests
		hist_vc = vc;

	%}INITIALIZATION


	for i=1:settings.epochs
		c = round(vc);

		[m, f] = compute_miss(in, c, in.lambda);

		% Historical data
		hist_m = [hist_m, sum(m,2) ]; hist_f = [hist_f, sum(f,2) ];

		M = m*1.0./f; M(isnan(M) )=0; % Current miss ratio

		M_prime = (M .- LM)*1.0 ./ (c .- Lc ); % derivative of miss ratio

		if all(M_prime>=0) || !only_plausible_updates

			F = f / sum(f); % request frequency
			r = (1.0/sqrt(N) ) * ones(N,1);
			s = -F .* M_prime; % direction of steepest discent 
			delta_vc = s .- (s'*r) * r;

			if (boost && any(delta_vc)!=0 )
				boost_factor = 1.0/max(abs(delta_vc) );
				delta_vc = boost_factor * delta_vc;
			end

			nvc = (vc .+ delta_vc);

			%{COPE WITH DISCRETE VALUES AND INCONSISTENCIES
				% Guarantee that each CP has at least 1 cache slot
				while ( any( round(nvc) < ones(N,1) ) )
					lucky = max(find( round(nvc) < ones(N,1)) );
					unlucky_candidates = find( round(nvc) > ones(N,1) );
					unlucky = unlucky_candidates( unidrnd( length(unlucky_candidates) ) );
					nvc(unlucky) = nvc(unlucky ) - 1;
					nvc(lucky) = nvc(lucky)+1;
				end

				difference = sum(round(nvc) ) - in.K;
				while (difference > 0)
					for d=1:difference
						unlucky_candidates = find( round(nvc)>1 );
						unlucky = unlucky_candidates(unidrnd( length(unlucky_candidates) ) );
						nvc(unlucky) = nvc(unlucky ) - 1;
					end
				end
				while (difference<0)
					lucky = unidrnd(N);
					nvc(lucky) = nvc(lucky ) + 1;
					difference++;
				end

			%}COPE WITH DISCRETE VALUES AND INCONSISTENCIES

			%{CHECK
			if (severe_debug)
				if (any(isnan(delta_vc) ) )
					delta_vc
					error("Error: delta_vc cannot be nan")
				end

				delta_vc_2 = (1.0/N ) * (F' * M_prime) * ones(N,1) .- (F .* M_prime);
				if (boost  && any(delta_vc_2)!=0 )
					boost_factor = 1.0/max(abs(delta_vc_2) );
					delta_vc_2 = boost_factor * delta_vc_2;
				end

				if ( abs(delta_vc - delta_vc_2) > 1e-6 )
					delta_vc
					delta_vc_2
					error("Error");
				end

				if (sum(delta_vc) > 1e-7 )
					delta_vc
					sum(delta_vc)
					error("Error");
				end

				if (sum(nvc) < in.K-N)
					error("error")
				end

				if  any( c == Lc) 
					Lc
					c
					error("Error")
				endif

				if ( any( round(vc)!= c ) )
					vc
					c
					error("Error")
				end
			end
			%}CHECK



			updated_CPs = round(nvc) != c;
			Lc(updated_CPs) = c (updated_CPs);
			LM(updated_CPs) = M (updated_CPs);
			vc = nvc;
			hist_vc = [hist_vc, vc];


		end

	end%for

	save(settings.outfile);
end%function
