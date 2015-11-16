%script
global severe_debug = 1;
addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
mdat_folder = "data/rawdata/coeff";
max_parallel = 7;

settings.save_mdat_file = true;
overwrite = true;
methods_ = {"descent", "dspsa_orig", "dspsa_enhanced", "optimum"};
methods_ = {"dspsa_orig"};
normalizes = [true, false];
coefficientss = {"no", "simple"};
lambdas = [1e4]; %req/s
tot_times = [30]; %total time(hours)
Ts = [1e2]; % epoch duration (s)
overall_ctlgs = [1e5];
ctlg_epss = [0];
alpha0s = [1];
alpha_epss = [0];
req_epss = [-1]; % if -1, req_proportion must be explicitely set
req_proportion=[0.64 0.04 0.04 0.04 0.04 0.04 0.04 0.04 0.04 0.04];
Ns = [10];
Ks = [1e2]; %cache slots
seeds = [1];

%%%%%
%avg_overall_reqs=[1e6];
%epochss = [1e1 1e2 1e3 1e4 1e5 1e6];
%%%%%%

ctlg_perms_to_consider = [1];
R_perms_to_consider = [1];
active_processes = 0;
for seed = seeds
	rand("state",seed);
	for alpha0 = alpha0s
	for alpha_eps = alpha_epss
	for req_eps = req_epss
	for overall_ctlg=overall_ctlgs
	for ctlg_eps = ctlg_epss
	for N = Ns
		%{CHECKS
		if mod(N,2) != 0; error("Only an even number of CPs are accepted"); end
		if req_eps==-1; 
			if length(req_proportion)!=N; disp(req_proportion);disp(N);error("error"); end; 
			if abs( sum(req_proportion) - 1) > 1e-5; 
				disp(req_proportion); disp(sum(req_proportion)); error("error"); 
			end; 
		end;
		%}CHECKS

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

		for ctlg_perm=ctlg_perms_to_consider
			in.ctlg_perm = ctlg_perm;
			in.catalog = ctlg_perms(:,ctlg_perm);
			zipf=[]; % I reset the zipf, since it depends on the alpha and the ctlg
			for tot_time = tot_times
			for T = Ts
				settings.epochs = round(tot_time*3600/T);
 				%{CHECK
				if settings.epochs < 1; error("error");	end;
				%}CHECK

				for lambda = lambdas
				%{BUILD R_perms
				avg_req_per_epoch = lambda * T;
				if req_eps != -1
					avg_req_per_epoch_per_CP = avg_req_per_epoch/in.N;
					R = differentiated_vector(N, avg_req_per_epoch_per_CP, req_eps); 
					R_perms = [R, flipud(R)];
				else
					R = avg_req_per_epoch * req_proportion';
					R_perms_to_consider = [1];
					R_perms = R;
				end
					%{CHECK
					if  severe_debug

						%due to the rounding of epochs
						additional_requests = ( settings.epochs-tot_time*3600/T) * lambda;

						tot_effective_req = lambda*T*settings.epochs;
						if any(abs(sum(R_perms*settings.epochs,1) - tot_effective_req )>1e-5)

							exact_epochs = tot_time*3600/T
							tot_effective_req
							additional_requests
							avg_req_per_epoch
							req_per_permutation_per_epoch = sum(R_perms,1)
							lambda
							tot_seconds = tot_time*3600
							R_perms'
							epochs = settings.epochs
							T
							req_per_epoch = sum(R_perms,1)
							avg_overall_req = lambda*tot_time*3600
							tot_effective_req
							error("Total number of requests does not match");
						end
					end
					%}CHECK
				%}BUILD R_perms 

				for R_perm=R_perms_to_consider
					in.R_perm = R_perm;
					in.R = R_perms(:,R_perm);
					for K=Ks
						in.K = K;

						for i=1:length(methods_)
							method = methods_{i};

							%{NORMALIZE AND COEFF ONLY WHEN IT MATTERS
							active_normalizes = normalizes;
							if !strcmp(method,"dspsa_orig")
								active_normalizes = [false];
							end

							active_coefficientss = coefficientss;
							if strcmp(method,"optim") || strcmp(method,"dspsa_enhanced")
								active_coefficientss = {"no"};
							end
							%}NORMALIZE AND COEFF ONLY WHEN IT MATTERS

							for settings.normalize = active_normalizes
							for idx_coefficient = 1:length(active_coefficientss)
								settings.coefficients = active_coefficientss{idx_coefficient};
				
								%{NAME
								if strcmp(method,"optimum")
									% These parameters do not influence the result and thus I 
									% keep a unique name
									settings.epochs = 1e6;
									avg_overall_req=1e8;
								end

								req_str=[];in.req_str_inner=[];
								if req_eps == -1
									in.req_str_inner = strrep(strrep(strrep(mat2str(req_proportion,2), "[", ""), "]","")," ","_");
									req_str = sprintf("req_prop_%s",in.req_str_inner);
								else
									in.req_str_inner = sprintf("%g", req_eps);
									req_str = sprintf("req_eps_%s", in.req_str_inner);
								end


								settings.simname = ...
									sprintf("%s/N_%d-ctlg_%.1g-ctlg_eps_%g-ctlg_perm_%d-alpha0_%g-alpha_eps_%g-lambda_%g-%s-R_perm_%d-T_%.1g-K_%.1g-%s-norm_%g-coeff_%s-tot_time_%g-seed_%d",...
									mdat_folder,N,overall_ctlg,ctlg_eps,   ctlg_perm,   alpha0,   alpha_eps,   lambda,req_str,R_perm, T,     K, method,settings.normalize, settings.coefficients, tot_time,   seed);
								settings.outfile = sprintf("%s.mdat",settings.simname);
								settings.logfile = sprintf("%s.log",settings.simname);
								settings.infile = sprintf("%s.in",settings.simname);
								%{NAME

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
										case "descdata/rawdata/with10/N_10-ctlg_1e+05-ctlg_eps_0-ctlg_perm_1-alpha0_1-alpha_eps_0-lambda_10000-req_prop_0.64_0.04_0.04_0.04_0.04_0.04_0.04_0.04_0.04_0.04-R_perm_1-T_1e+02-K_1e+02-dspsa_orig-tot_time_3-seed_1.inent"
											function_name = "cumulative_steepest_descent";

										case "dspsa_enhanced"
											settings.enhanced = true;
											function_name = "dspsa";

										case "dspsa_orig"
											settings.enhanced = false;
											function_name = "dspsa";

										case "optimum"
											function_name = "optimum";

										otherwise
											method
											error("method not recognized");
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
						end%coefficient end
						end%normalize for
					end%K for
				end%R_perm for
				end%lambda for
			end%T for
			end%tot_time for
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
