%script
global severe_debug = 1;
addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
mdat_folder = "data/rawdata";
max_parallel = 1;

overwrite = false;
methods_ = {"descent", "dspsa_orig","dspsa_enhanced", "optimum"};
methods_ = {"dspsa_orig", "descent"};
epochss = [1e6];
avg_overall_req=1e8;
overall_ctlgs = [1e6 1e5 1e4];
ctlg_epss = [0.4];
alpha0s = [1];
alpha_epss = [0.4];
req_epss = [0.4];
Ns = [2];
Ks = [1e1]; %cache slots
seeds = 1 ;

active_processes = 0;
for seed = seeds
	rand("state",seed);
	for alpha0 = alpha0s
	for alpha_eps = alpha_epss
	for req_eps = req_epss
	for overall_ctlg=overall_ctlgs
	for ctlg_eps = ctlg_epss
	for N = Ns
		if mod(N,2) != 0
			error("Only an even number of CPs are accepted")
		end

		in.ctlg_eps = ctlg_eps;
		in.overall_ctlg = overall_ctlg;
		in.N = N;
		in.alpha0 = alpha0;
		in.alpha_eps = alpha_eps;
		in.req_eps = req_eps;

		in.alpha = differentiated_vector(N, alpha0, alpha_eps);

		avg_ctlg = overall_ctlg/N;
		ctlg = round(differentiated_vector(N, avg_ctlg, ctlg_eps) );
		ctlg_perms = [ctlg, flipud(ctlg)];

		for ctlg_perm=1:size(ctlg_perms, 2)
			in.ctlg_perm = ctlg_perm;
			in.catalog = ctlg_perms(:,ctlg_perm);
			zipf=[]; % I reset the zipf, since it depends on the alpha and the ctlg
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
				R = differentiated_vector(N, avg_req_per_epoch_per_CP, req_eps); 
				R_perms = [R, flipud(R)];
				%}BUILD R_perms 

				for R_perm=1:size(R_perms, 2)
					in.R_perm = R_perm;
					in.R = R_perms(:,R_perm);
					for K=Ks
						in.K = K;

						for i=1:length(methods_)
							method = methods_{i};
							settings.simname = ...
								sprintf("%s/N_%d-ctlg_%.1g-ctlg_eps_%g-ctlg_perm_%d-alpha0_%g-alpha_eps_%g-req_eps_%g-R_perm_%d-epochs_%.1g-K_%.1g-%s-totreq_%.1g-seed_%d",...
								mdat_folder,N,overall_ctlg,  ctlg_eps,   ctlg_perm,   alpha0,   alpha_eps,   req_eps,   R_perm,   epochs,     K,method, avg_overall_req, seed);
							settings.outfile = sprintf("%s.mdat",settings.simname);
							settings.logfile = sprintf("%s.log",settings.simname);
							settings.infile = sprintf("%s.in",settings.simname);

							if !exist(settings.outfile) || overwrite
								%{GENERATE lambdatau
								if length(zipf)==0
									% the appropriate zipf has not been yet generated
									zipf = zeros(N, max(in.catalog) );
									for j=1:in.N
										zipf(j, 1:in.catalog(j)) = ...
											(ZipfPDF(in.alpha(j), in.catalog(j)) )';
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
				end%R_perm for
			end%epochs for
		end%ctlg_perm for
	end%N for
	end%ctlg_eps for
	end%overall_ctlg for
	end%eps for
	end%alpha_eps for
	end%alpha0 for
end%seed for

while active_processes > 0
	waitpid(-1);
	active_processes--;
end
