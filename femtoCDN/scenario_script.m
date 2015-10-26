%script
global severe_debug = 1;
addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
mdat_folder = "data/rawdata";

methods_ = {"descent", "dspsa_orig","dspsa_enhanced","optimum"};
requests_per_epochs = [1e2 1e4 1e6];
total_requests=1e9;
catalogs = [1e5];
epsilons = [0.5];
Ks = [1e3]; %cache slots
seeds = 1 ;

for seed = seeds
	rand("state",seed);
	for epsilon = epsilons
		for catalog=catalogs
			in.alpha=[1-epsilon; 1+epsilon];
			in.N = length(in.alpha); %num CPs
			in.catalog=repmat(catalog, in.N, 1);
			zipf=[];

			if mod(in.N,2) != 0
				error("Only an even number of CPs are accepted")
			end


			for requests_per_epoch = requests_per_epochs
				in.R = repmat(requests_per_epoch/in.N, in.N, 1);
				settings.epochs = round(total_requests/requests_per_epoch);

				%{CHECK
				if settings.epochs < 1
					error("error");
				end
				%}CHECK

				for K=Ks
					in.K = K;

					for i=1:length(methods_)
						method = methods_{i};
						settings.outfile = ...
							sprintf("%s/ctlg_%g-eps_%g-req_per_epoch_%g-K_%g-%s-seed_%d.mdat",...
							mdat_folder,catalog,epsilon,requests_per_epoch, K, method, seed);

						if !exist(settings.outfile)
							%{GENERATE lambda
							if length(zipf)==0
								for j=1:in.N
									zipf = [zipf; (ZipfPDF(in.alpha(j), in.catalog(j)) )'];
								end
							%else it means that the zipf has already been generated
							end

							in.lambda=[];
							for j=1:in.N
								in.lambda = [in.lambda;  zipf(j,:) .* in.R(j) ];
							end
							%}GENERATE lambda


							switch method
								case "descent"
									cumulative_steepest_descent(in, settings);

								case "dspsa_orig"
									settings.enhanced = false;
									dspsa(in, settings);

								case "dspsa_enhanced"
									settings.enhanced = true;
									dspsa(in, settings);

								case "optimum"
									optimum(in,settings);

								otherwise
									method
									error("method not recognised");
							end%switch
							disp (sprintf("%s written", settings.outfile) );
						else
							disp (sprintf("%s exists", settings.outfile) );
						end
					end%methods for
				end%K for
			end%request for
		end%catalog for
	end%epsilon for
end%seed for
