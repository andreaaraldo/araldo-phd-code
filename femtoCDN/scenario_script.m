%script
global severe_debug = 1;
addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
mdat_folder = "~/remote_archive/femtoCDN/transmissions";
max_parallel = 24;


parse=true; % false if you want to run the experiment.
settings.save_mdat_file = true;
overwrite = false;
methods_ = {"csda", "dspsa_orig", "opencache", "optimum", "unif"};
methods_ = {"opencache", "unif"};
normalizes = {"no", "max", "norm"};
normalizes = {"no"};
coefficientss = {"no", "simple", "every10","every100", "adaptive","adaptiveaggr", "insensitive", "smoothtriang", "triang"};
coefficientss = {"adaptive","adaptiveaggr", "insensitive", "smoothtriang", "triang"};
boosts = [1];
lambdas = [100]; %req/s 
tot_times = [1]; %total time(hours)
Ts = [100]; % epoch duration (s)
overall_ctlgs = [1e8];
ctlg_epss = [0];
alpha0s = [1];
alpha_epss = [0];
req_epss = [-1]; % if -1, req_proportion must be explicitely set
in.req_proportion=[0.28 0.28 0.28 0.10 0 0 0 0.02 0.02 0.02];
in.req_proportion=[0.13 0.75 0.02 0.10];
ps = [4];
Ks = [1e6]; %cache slots
projections = {"no", "fixed", "prop", "euclidean"};
projections = {"euclidean"};
seeds = 1;




%{ CONSTANTS
global COEFF_NO=0; global COEFF_SIMPLE=1; global COEFF_10=2; global COEFF_100=3; 
	global COEFF_ADAPTIVE=4; global COEFF_ADAPTIVE_AGGRESSIVE=5; global COEFF_INSENSITIVE=6;
	global COEFF_TRIANGULAR=7; global COEFF_SMOOTH_TRIANGULAR=8; global COEFF_ZERO=9;
global NORM_NO=0; global NORM_MAX=1; global NORM_NORM=2;
global PROJECTION_NO=0; global PROJECTION_FIXED=1; global PROJECTION_PROP=2; 
	global PROJECTION_EUCLIDEAN=3;
%} CONSTANTS



ctlg_perms_to_consider = [1];
R_perms_to_consider = [1];
active_processes = 0;
for seed = seeds
	settings.seed = seed;
	rand("seed",seed);
	for alpha0 = alpha0s
	for alpha_eps = alpha_epss
	for req_eps = req_epss
	for overall_ctlg=overall_ctlgs
	for ctlg_eps = ctlg_epss
	for p = ps
		%{CHECKS
		if mod(p,2) != 0; error("Only an even number of CPs are accepted"); end
		if req_eps==-1; 
			if length(in.req_proportion)!=p; disp(in.req_proportion);disp(p);error("error"); end; 
			if abs( sum(in.req_proportion) - 1) > 1e-5; 
				disp(in.req_proportion); disp(sum(in.req_proportion)); error("error"); 
			end; 
		end;
		%}CHECKS

		in.ctlg_eps = ctlg_eps;
		in.overall_ctlg = overall_ctlg;
		in.p = p;
		in.alpha0 = alpha0;
		in.alpha_eps = alpha_eps;
		in.req_eps = req_eps;
		in.alpha = differentiated_vector(p, alpha0, alpha_eps);

		avg_ctlg = overall_ctlg/p;
		ctlg = round(differentiated_vector(p, avg_ctlg, ctlg_eps) );
		ctlg_perms = [ctlg, flipud(ctlg)];

		for ctlg_perm=ctlg_perms_to_consider
			in.ctlg_perm = ctlg_perm;
			in.catalog = ctlg_perms(:,ctlg_perm);
			zipf=[]; % I reset the zipf, since it depends on the alpha and the ctlg
			for tot_time = tot_times
			for in.T = Ts
				settings.epochs = round(tot_time*3600/in.T);
 				%{CHECK
				if settings.epochs < 1; error("error");	end;
				%}CHECK

				for in.lambda = lambdas
				%{BUILD R_perms
				avg_req_per_epoch = in.lambda * in.T;
				if req_eps != -1
					avg_req_per_epoch_per_CP = avg_req_per_epoch/in.p;
					R = differentiated_vector(p, avg_req_per_epoch_per_CP, req_eps); 
					R_perms = [R, flipud(R)];
				else
					R = avg_req_per_epoch * in.req_proportion';
					R_perms_to_consider = [1];
					R_perms = R;
				end
					%{CHECK
					if  severe_debug

						%due to the rounding of epochs
						additional_requests = ( settings.epochs-tot_time*3600/in.T) * in.lambda;

						tot_effective_req = in.lambda*in.T*settings.epochs;
						if any(abs(sum(R_perms*settings.epochs,1) - tot_effective_req )>1e-4)

							exact_epochs = tot_time*3600/in.T
							tot_effective_req
							additional_requests
							avg_req_per_epoch
							req_per_permutation_per_epoch = sum(R_perms,1)
							in.lambda
							tot_seconds = tot_time*3600
							R_perms'
							epochs = settings.epochs
							in.T
							req_per_epoch = sum(R_perms,1)
							avg_overall_req = in.lambda*tot_time*3600
							tot_effective_req
							difference = abs(sum(R_perms*settings.epochs,1) - tot_effective_req )
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

						for settings.boost = boosts
						for i=1:length(methods_)
							method = methods_{i};
							settings.method = method;

							%{NORMALIZE, COEFF AND PROJECTIONS ONLY WHEN IT MATTERS
							active_coefficientss = coefficientss;
							if strcmp(method,"optim") || strcmp(method,"csda") || strcmp(method,"unif")
								active_coefficientss = {"no"};
							end

							active_projections = projections;
							if strcmp(method,"optim") || strcmp(method,"csda") || strcmp(method,"unif")
								active_projections = {"no"};
							end

							if settings.boost != 1
								error("boost must be 1");
							end
							%}NORMALIZE, COEFF AND PROJECTIONS ONLY WHEN IT MATTERS

							for idx_normalize = 1:length(normalizes);
							for idx_coefficient = 1:length(active_coefficientss)
							for idx_projection = 1:length(projections)
								coefficients = active_coefficientss{idx_coefficient};
								normalize = normalizes{idx_normalize};
								settings.projection_str = projections{idx_projection};

								switch coefficients
									case "no"
										settings.coefficients = COEFF_NO;
									case "simple"
										settings.coefficients = COEFF_SIMPLE;
									case "every10"
										settings.coefficients = COEFF_10;
									case "every100"
										settings.coefficients = COEFF_100;
									case "adaptive"
										settings.coefficients = COEFF_ADAPTIVE;
									case "adaptiveaggr"
										settings.coefficients = COEFF_ADAPTIVE_AGGRESSIVE;
									case "insensitive"
										settings.coefficients = COEFF_INSENSITIVE;
									case "triang"
										settings.coefficients = COEFF_TRIANGULAR;
									case "smoothtriang"
										settings.coefficients = COEFF_SMOOTH_TRIANGULAR;
									case "zero"
										settings.coefficients = COEFF_ZERO;
									otherwise
										error "coefficients incorrect";
								end

								switch settings.projection_str
									case "no"
										settings.projection = PROJECTION_NO;
									case "fixed"
										settings.projection = PROJECTION_FIXED;
									case "prop"
										settings.projection = PROJECTION_PROP;
									case "euclidean"
										settings.projection = PROJECTION_EUCLIDEAN;
									otherwise
										error "incorrect projection";
								end

								switch normalize
									case "no"
										settings.normalize = NORM_NO;
									case "max"
										settings.normalize = NORM_MAX;
									case "norm"
										settings.normalize = NORM_NORM;
									otherwise
										error (sprintf("normalize \"%s\" not recognized",normalize) );
								end

								%{NAME
								if strcmp(method,"optimum")
									% These parameters do not influence the result and thus I 
									% keep a unique name
									settings.epochs = 1e6;
									avg_overall_req=1e8;
								end

								req_str=[];in.req_str_inner=[];
								if req_eps == -1
									in.req_str_inner = strrep(strrep(strrep(mat2str(in.req_proportion,2), "[", ""), "]","")," ","_");
									req_str = sprintf("req_prop_%s",in.req_str_inner);
								else
									in.req_str_inner = sprintf("%g", req_eps);
									req_str = sprintf("req_eps_%s", in.req_str_inner);
								end


								settings.simname = ...
									sprintf("%s/p_%d-ctlg_%.1g-ctlg_eps_%g-ctlg_perm_%d-alpha0_%g-alpha_eps_%g-lambda_%g-%s-R_perm_%d-T_%.1g-K_%.1g-%s-norm_%s-coeff_%s-projection_%s-boost_%g-tot_time_%g-seed_%d",...
									mdat_folder,p,overall_ctlg,ctlg_eps,   ctlg_perm,   alpha0,   alpha_eps,   in.lambda,req_str,R_perm, in.T,     K, method, normalize, coefficients, settings.projection_str,settings.boost, tot_time,   seed);
								settings.outfile = sprintf("%s.mdat",settings.simname);
								settings.logfile = sprintf("%s.log",settings.simname);
								settings.infile = sprintf("%s.in",settings.simname);
								%{NAME

								if !exist(settings.outfile) || overwrite || parse
									%{GENERATE lambdatau
									if length(zipf)==0
										% the appropriate zipf has not been yet generated
										zipf = zeros(p, max(in.catalog) );
										for j=1:in.p
											zipf(j, 1:in.catalog(j)) = ...
												(ZipfPDF(in.alpha(j), in.catalog(j)) )';
										end
									%else it means that the zipf has already been generated
									end

									in.lambdatau=[]; %avg #req per each object
									for j=1:in.p
										in.lambdatau = [in.lambdatau;  zipf(j,:) .* in.R(j) ];
									end
									%}GENERATE lambdatau


									function_name = [];
									switch method
										case "csda"
											function_name = "dspsa";
										case "dspsa_orig"
											function_name = "dspsa";
										case "opencache"
											function_name = "dspsa";
										case "optimum"
											function_name = "optimum";
										case "unif"
											function_name = "dspsa";
										otherwise
											method
											error("method not recognized");
									end%switch

									if !parse %so I want to run the experiment
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
									else % I want to parse the experiment
										parse_results(in, settings);
									end % parse
								else
									disp (sprintf("%s exists", settings.outfile) );
							
								end

							end%boost for
							end%methods for
						end%projection
						end%coefficient end
						end%normalize for
					end%K for
				end%R_perm for
				end%lambda for
			end%T for
			end%tot_time for
		end%ctlg_perm for
	end%p for
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
