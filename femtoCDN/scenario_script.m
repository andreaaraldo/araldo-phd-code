%script
global severe_debug = 1;
addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
mdat_folder = "data/rawdata";
max_parallel = 8;

overwrite = true;
methods_ = {"descent", "dspsa_orig","dspsa_enhanced", "optimum"};
methods_ = {"optimum"};
epochss = [1e6];
avg_overall_req=1e8;
catalogs = [1e5];
alpha0s = [0.7 1];
alpha_epss = [0.2 0.4];
req_epss = [0.2 0.4];
Ns = [2 4 8];
Ks = [1e1 1e2 1e3]; %cache slots
seeds = 1 ;

active_processes = 0;
for seed = seeds
	rand("state",seed);
	for alpha0 = alpha0s
	for alpha_eps = alpha_epss
	for req_eps = req_epss
	for catalog=catalogs
	for N = Ns
		in.N = N;
		in.alpha0 = alpha0;
		in.alpha_eps = alpha_eps;
		in.req_eps = req_eps;

		%{BUILD alpha
		delta_alpha = 2*alpha_eps / (N-1);
		in.alpha = repmat(alpha0-alpha_eps, N,1);
		for j=2:in.N
			in.alpha(j,1) = in.alpha(j,1) + (j-1)*delta_alpha;
		end
		%}BUILD alpha
		in.catalog=repmat(catalog, in.N, 1);
		zipf=[];

		if mod(in.N,2) != 0
			error("Only an even number of CPs are accepted")
		end


		for epochs = epochss
			settings.epochs = epochs;

			%{CHECK
			if settings.epochs < 1
				error("error");
			end
			%}CHECK

			%{BUILD R_perms
			% avg #req per epoch per CP
			avg_req_per_epoch_per_CP = avg_overall_req/(epochs*in.N);
			delta_R = 2*avg_req_per_epoch_per_CP*req_eps / (N-1) ;
			R = repmat( (1-req_eps)*avg_req_per_epoch_per_CP, in.N, 1); 
			for j=2:in.N
				R(j,1) = R(j,1) + (j-1)*delta_R;
			end
			R_perms = [R, flipud(R)];
			%}BUILD R_perms 

			for perm=1:size(R_perms, 2)
				in.perm = perm;
				in.R = R_perms(:,perm);
				for K=Ks
						in.K = K;

						for i=1:length(methods_)
							method = methods_{i};
							settings.simname = ...
								sprintf("%s/N_%d-ctlg_%.1g-alpha0_%g-alpha_eps_%g-req_eps_%g-perm_%d-epochs_%.1g-K_%.1g-%s-totreq_%.1g-seed_%d",...
								mdat_folder,N,catalog,alpha0,alpha_eps,req_eps,perm, epochs, K,...
								method, avg_overall_req, seed);

							settings.outfile = sprintf("%s.mdat",settings.simname);
							settings.logfile = sprintf("%s.log",settings.simname);
							settings.infile = sprintf("%s.in",settings.simname);

							if !exist(settings.outfile) || overwrite
								%{GENERATE lambdatau
								if length(zipf)==0
									for j=1:in.N
										zipf = [zipf; (ZipfPDF(in.alpha(j), in.catalog(j)) )'];
									end
								%else it means that the zipf has already been generated
								end

								in.lambdatau=[]; %avg #req per each object
								for j=1:in.N
									in.lambdatau = [in.lambdatau;  zipf(j,:) .* in.R(j) ];
								end
								%}GENERATE lambdatau


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
									quit;
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
			end%perm for
		end%epochs for
	end%N for
	end%catalog for
	end%eps for
	end%alpha_eps for
	end%alpha0 for
end%seed for

while active_processes > 0
	waitpid(-1);
	active_processes--;
end
