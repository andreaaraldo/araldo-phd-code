%script
global severe_debug = 1;
addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
mdat_folder = "data/rawdata";
max_parallel = 8;
overwrite = true;

methods_ = {"descent", "dspsa_orig","dspsa_enhanced","optimum"};
requests_per_epochs = [1e3 1e6];
total_requests=1e7;
catalogs = [1e5];
epsilons = [0.5];
Ks = [1e3]; %cache slots
seeds = 1 ;

active_processes = 0;
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
						settings.simname = ...
							sprintf("%s/ctlg_%g-eps_%g-req_per_epoch_%g-K_%g-%s-totreq_%g-seed_%d",...
							mdat_folder,catalog,epsilon,requests_per_epoch, K, method, ...
							total_requests, seed);

						settings.outfile = sprintf("%s.mdat",settings.simname);
						settings.logfile = sprintf("%s.log",settings.simname);
						settings.infile = sprintf("%s.in",settings.simname);

						if !exist(settings.outfile) || overwrite
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


							function_name = [];
							switch method
								case "descent"
									%cumulative_steepest_descent(in, settings);
									function_name = "cumulative_steepest_descent";

								case "dspsa_orig"
									settings.enhanced = false;
									%dspsa(in, settings);
									function_name = "dspsa";


								case "dspsa_enhanced"
									settings.enhanced = true;
									%dspsa(in, settings);
									function_name = "dspsa";

								case "optimum"
									%optimum(in,settings);
									function_name = "optimum";

								otherwise
									method
									error("method not recognised");
							end%switch

							save(settings.infile);
							command = ...
								sprintf("octave --quiet --eval \"%s([], [], '%s') \" > %s 2>&1",...
								function_name, settings.infile, settings.logfile);
							if active_processes >= max_parallel
								waitpid(-1);
								active_processes--;
							end
							pid = fork();
							if pid==0
								% I am the child
								[exit_code, output] = system(command );
								if ( exit_code != 0)
									error(sprintf("ERROR in executing %s\n\nError is %s. See %s",
											command, output, settings.logfile) );
								end
							elseif pid>0
								printf("Sim %s launched with pid %g\n", settings.simname, pid);
								active_processes++;
							else
								pid
								error "Error in the fork";
							end%pid if
						else
							disp (sprintf("%s exists", settings.outfile) );
							
						end
					end%methods for
				end%K for
			end%request for
		end%catalog for
	end%epsilon for
end%seed for
