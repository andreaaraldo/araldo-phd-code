%The algoritm implemented here is from 
% Megory-Cohen, Igal and Ela, Givat - "Dynamic Cache Partitioning by Modified Steepest Descent" 
global severe_debug = true;
addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
%pkg load statistics;
%pkg load communications; % for randint


rounding = false;

alpha=[1.2; 1.1];
R = [1e6; 1e6 ];
catalog=[1e3; 1e3];

N = length(alpha); %num CPs
K = 10; %cache slots
boost =  1;

%{INITIALIZATION
	Lc = LM = zeros(N,1);
	c=repmat( round(K*1.0/N), N-1,1 ); %configuration
	c = [c; K-sum(c)];

	lambda=[];
	for j=1:N
		lambda = [lambda; (ZipfPDF(alpha(j), catalog(j)) )' .* R(j) ];
	end
%}INITIALIZATION


for i=1:10000
	%{CHECK
	if(severe_debug)
		if ( sum( round(c) < ones(N,1) ) != 0 )
			c
			error("Inconsistent c")
		end	
	end
	%}CHECK

	%{REQUEST GENERATION
	requests = [];
	max_catalog = max(catalog);
	for j=1:N
		these_requests = zeros(1,max_catalog);
		these_requests(1:catalog(j) ) = poissrnd(lambda(j,:) );
		requests = [requests; these_requests ];
	end%for
	%}REQUEST GENERATION

	m = sum(requests(:,round(c)+1 : size(requests,2) ) , 2); % misses

	f = sum(requests, 2 ); % total requests
	M = m*1.0./f; M(isnan(M) )=0; % Current miss ratio

	% This is the original formula
	M_prime = (M .- LM)*1.0 ./ (round(c) .- round(Lc) ); % derivative of miss ratio

	F = f / sum(f); % request frequency
	r = (1.0/sqrt(N) ) * ones(N,1);
	s = -F .* M_prime; % direction of steepest discent 
	delta_c = s .- (s'*r) * r;
	delta_c = boost * delta_c;

	Nc = (c .+ delta_c);

	%{COPE WITH DISCRETE VALUES AND INCONSISTENCIES
		if (rounding) 
			Nc = round(Nc);
		end

		while ( any( round(Nc) < ones(N,1) ) != 0 )
			unlucky = unidrnd(N);
			if (Nc(unlucky)>1 )
				Nc(unlucky) = Nc(unlucky ) - 1;
			end
			lucky = min(find( round(Nc) < ones(N,1)) );
			Nc(lucky) = Nc(lucky)+1;
		end

		difference = sum(round(Nc) ) - K;
		while (difference > 0)
			for d=1:difference
				unlucky_candidates = find( round(Nc)>1 );
				unlucky = unlucky_candidates(unidrnd( length(unlucky_candidates) ) );
				if (Nc(unlucky)>1 )
					Nc(unlucky) = Nc(unlucky ) - 1;
					difference--;
				end
			end
		end
		while (difference<0)
			lucky = unidrnd(N);
			Nc(lucky) = Nc(lucky ) + 1;
			difference++;
		end

	%}COPE WITH DISCRETE VALUES AND INCONSISTENCIES

	%{CHECK
	if (severe_debug)
		delta_c_2 = (1.0/N ) * (F' * M_prime) * ones(N,1) .- (F .* M_prime);
		delta_c_2 = boost * delta_c_2;
		if ( abs(delta_c - delta_c_2) > 1e-6 )
			delta_c
			delta_c_2
			error("Error");
		end

		if (sum(delta_c) > 1e-7 )
			delta_c
			sum(delta_c)
			error("Error");
		end

		if (sum(Nc) < K-N)
			error("error")
		end
	end
	%}CHECK



	updated_CPs = round(Nc) != round(c);
	Lc(updated_CPs) = c (updated_CPs);
	LM(updated_CPs) = M (updated_CPs);
	c = Nc;

	disp(c')

end%for
