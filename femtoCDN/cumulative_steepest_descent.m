function cumulative_steepest_descent(in)
	% SETTINGS
	boost =  false;
	only_plausible_updates = false;
	global severe_debug
	severe_debug

	N = length(in.alpha); %num CPs

	%{INITIALIZATION
		Lc = LM = zeros(N,1);
		vc=repmat( in.K*1.0/N, N,1 ); %virtual configuration

		lambda=[];
		for j=1:N
			lambda = [lambda; (ZipfPDF(in.alpha(j), in.catalog(j)) )' .* in.R(j) ];
		end
	%}INITIALIZATION


	for i=1:10000
		c = round(vc);

		%{REQUEST GENERATION
		requests = [];
		max_catalog = max(in.catalog);
		for j=1:N
			these_requests = zeros(1,max_catalog);
			these_requests(1:in.catalog(j) ) = poissrnd(lambda(j,:) );
			requests = [requests; these_requests ];
		end%for
		%}REQUEST GENERATION

		ordinal = repmat(1:max_catalog, N, 1);
		cache_indicator_negated = ordinal > repmat(c,1,max_catalog);
		m = [];
		for j=1:N
			m = [m; requests(j,:) * cache_indicator_negated(j,:)'];
		end

		f = sum(requests, 2 ); % total requests
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
			disp(vc(2)/sum(vc) )

		end

	end%for

end%function