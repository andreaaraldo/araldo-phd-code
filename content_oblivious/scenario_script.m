%script
global severe_debug = 0;
addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
settings.mdat_folder = "~/pint_archive/content_oblivious/journal/downloads";
max_parallel = 6;
warning("error", "Octave:divide-by-zero");
warning ("error", "Octave:broadcast");



parse=false; % false if you want to run the experiment.
clean_tokens=false;
settings.save_mdat_file = true;
overwrite = false;
settings.compact_name=true;

settings.ON_hist_trash=true;

methods_ = {"csda", "dspsa_orig", "opencache", "optimum", "unif", "optimum_nominal","declaration"};
methods_ = {"opencache","unif","optimum"};
methods_ = {"opencache"};


normalizes = {"no", "max", "norm"};
normalizes = {"no"};
coefficientss = {"no", "simple", "every10","every100", "adaptive","adaptiveaggr", "insensitive", "smoothtriang", "triang"};
coefficientss = {"adaptive","adaptiveaggr", "insensitive", "smoothtriang", "triang", "smartsmooth", "linear", "moderate", "moderatelong", "linearlong","linearsmart10", "linearsmart100"};
coefficientss = {"triang", "moderate", "linearhalved5"};
coefficientss = {"linearhalved5"};

boosts = [1];
lambdas = [100]; %req
tot_times = [1]; %total time(hours)
Ts = [1,5, 10, 50, 100]; % epoch duration (s)
Ts = [100]; % epoch duration (s)
overall_ctlgs = [1e8];
CTLG_PROP=-1; % To split the catalog as the request proportion
ctlg_epss = [0];
alpha0s = [0.8];
alpha_epss = [0];
req_epss = [-1]; % if -1, req_proportion must be explicitely set
ONtimes = [1];%Fraction of time the object is on.
ONOFFspans = [70]; %How many days an ON-OFF cycle lasts on average

in.req_proportion=[0.70 0 0.24 0 0.01 0.01 0.01 0.01 0.01 0.01]';

ps = [length(in.req_proportion) ]; % Number of CPs
Ks = [1e6]; %cache slots
projections = {"no", "fixed", "prop", "euclidean"};
projections = {"euclidean"};
knows=[Inf]; %knowledge degree value
seeds = 1;



%{ CONSTANTS
global COEFF_NO=0; global COEFF_SIMPLE=1; global COEFF_10=2; global COEFF_100=3; 
	global COEFF_ADAPTIVE=4; global COEFF_ADAPTIVE_AGGRESSIVE=5; global COEFF_INSENSITIVE=6;
	global COEFF_TRIANGULAR=7; global COEFF_SMOOTH_TRIANGULAR=8; global COEFF_ZERO=9;
	global COEFF_SMART=10; global COEFF_SMARTPERC25=11; global COEFF_SMARTSMOOTH=12;
	global COEFF_MODERATE=13; global COEFF_LINEAR=14; 
	global COEFF_MODERATELONG=15; global COEFF_LINEARLONG=16; global COEFF_LINEARSMART10=17;
	global COEFF_LINEARSMART100=18; global COEFF_LINEARCUT25=19; global COEFF_LINEARCUT10=20;
	global COEFF_LINEARHALVED5=21; global COEFF_LINEARHALVED10=22;
	global COEFF_LINEARCUTCAUTIOUS10=23;	global COEFF_LINEARCUTCAUTIOUS25=24;
	global COEFF_LINEARCUTCAUTIOUSMODERATE10=25; global COEFF_LINEARCUTCAUTIOUSOTHER10=26;
	global COEFF_LINEARCUTCAUTIOUS10D2=27;
	global COEFF_LINEARCUTCAUTIOUS10D4=28; global COEFF_LINEARCUTCAUTIOUS10D8=29;
	global COEFF_LINEARCUTCAUTIOUS10D16=30; global COEFF_LINEARCUTCAUTIOUS10Dp=31;
	global COEFF_MODERATELONGNEW=32; global COEFF_MODERATENEW=33;
	global COEFF_LINEARHALVED5REINIT30MIN=34; global COEFF_LINEARHALVED5REINIT1DAY=35;
global NORM_NO=0; global NORM_MAX=1; global NORM_NORM=2;
global PROJECTION_NO=0; global PROJECTION_FIXED=1; global PROJECTION_PROP=2; 
	global PROJECTION_EUCLIDEAN=3;
%} CONSTANTS

warning("on", "backtrace");


ctlg_perms_to_consider = [1];

active_processes = 0;
for seed = seeds
	settings.seed = seed;
	rand("state",seed);randn("state",seed);randp("state",seed);
	for alpha0 = alpha0s
	for alpha_eps = alpha_epss
	for req_eps = req_epss
	for overall_ctlg=overall_ctlgs
	for ctlg_eps = ctlg_epss
	for p = ps
		%{CHECKS
		if mod(p,2) != 0; error("Only an even number of CPs are accepted"); end
		if req_eps==-1; 
			if length(in.req_proportion)!=p 
				disp(in.req_proportion);disp(p);error("error: size of request vector incorrect"); 
			end
			if abs( sum(in.req_proportion) - 1) > 1e-5
				disp(in.req_proportion); disp(sum(in.req_proportion)); 
				error("error: request vector does not sum up to 1"); 
			end
		end
		%}CHECKS

		in.ctlg_eps = ctlg_eps;
		in.overall_ctlg = overall_ctlg;
		in.p = p;
		in.alpha0 = alpha0;
		in.alpha_eps = alpha_eps;
		in.req_eps = req_eps;
		in.alpha = differentiated_vector(p, alpha0, alpha_eps);
		in.alpha = in.alpha(randperm(size(in.alpha) ) );

		avg_ctlg = overall_ctlg/p;
		if ctlg_eps!= CTLG_PROP
			in.ctlg = round(differentiated_vector(p, avg_ctlg, ctlg_eps) );
		else
			in.ctlg = in.req_proportion .* overall_ctlg;
		end


			popularity=[]; % I reset the popularity, since it depends on the alpha and the ctlg
			for in.tot_time = tot_times
			for in.know = knows % knowledge degree values
			for in.T = Ts
				settings.epochs = round(in.tot_time*3600/in.T);
 				%{CHECK
				if settings.epochs < 1; error("error");	end;
				%}CHECK

				for in.lambda = lambdas
					for K=Ks
						in.K = K;

						for settings.boost = boosts
						for i=1:length(methods_)
							method = methods_{i};
							settings.method = method;

							%{NORMALIZE, COEFF, PROJECTIONS AND T ONLY WHEN IT MATTERS
							active_coefficientss = coefficientss;
							active_projections = projections;
							if strcmp(method,"optimum") || strcmp(method,"optimum_nominal") || strcmp(method,"csda") || strcmp(method,"unif") || strcmp(method,"declaration") 
								active_coefficientss = {"no"};
								active_projections = {"no"};
							end

							if strcmp(method,"optimum_nominal")
								in.T = 0;
							end

							if settings.boost != 1
								error("boost must be 1");
							end
							%}NORMALIZE, COEFF, PROJECTIONS AND T ONLY WHEN IT MATTERS

							for in.ONtime = ONtimes
							for in.ONOFFspan = ONOFFspans
							for idx_normalize = 1:length(normalizes);
							for idx_coefficient = 1:length(active_coefficientss)
							for idx_projection = 1:length(projections)

								%{ CHECKS
									if in.ONtime != 1 && settings.ON_hist_trash
										error "The computation of trash is erroneous when in.ONtime is not 1"
									end
								%} CHECKS

								in.coefficients_str = active_coefficientss{idx_coefficient};
								in.normalize_str = normalizes{idx_normalize};
								settings.projection_str = projections{idx_projection};

								switch in.coefficients_str
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
									case "smart"
										settings.coefficients = COEFF_SMART;
									case "smartperc25"
										settings.coefficients = COEFF_SMARTPERC25;
									case "smartsmooth"
										settings.coefficients = COEFF_SMARTSMOOTH;
									case "moderate"
										settings.coefficients = COEFF_MODERATE;
									case "linear"
										settings.coefficients = COEFF_LINEAR;
									case "moderatelong"
										settings.coefficients = COEFF_MODERATELONG;
									case "linearlong"
										settings.coefficients = COEFF_LINEARLONG;
									case "linearsmart10"
										settings.coefficients = COEFF_LINEARSMART10;
									case "linearsmart100"
										settings.coefficients = COEFF_LINEARSMART100;
									case "linearcut25"
										settings.coefficients = COEFF_LINEARCUT25;
									case "linearcut10"
										settings.coefficients = COEFF_LINEARCUT10;
									case "linearhalved5"
										settings.coefficients = COEFF_LINEARHALVED5;
									case "linearhalved10"
										settings.coefficients = COEFF_LINEARHALVED10;
									case "linearcutcautious10"
										settings.coefficients = COEFF_LINEARCUTCAUTIOUS10;
									case "linearcutcautious25"
										settings.coefficients = COEFF_LINEARCUTCAUTIOUS25;
									case "linearcutcautiousmod10"
										settings.coefficients = COEFF_LINEARCUTCAUTIOUSMODERATE10;
									case "lincutcautious10d2"
										settings.coefficients = COEFF_LINEARCUTCAUTIOUS10D2;
									case "lincutcautious10d4"
										settings.coefficients = COEFF_LINEARCUTCAUTIOUS10D4;
									case "lincutcautious10d8"
										settings.coefficients = COEFF_LINEARCUTCAUTIOUS10D8;
									case "lincutcautious10d16"
										settings.coefficients = COEFF_LINEARCUTCAUTIOUS10D16;
									case "lincutcautious10dp"
										settings.coefficients = COEFF_LINEARCUTCAUTIOUS10Dp;
									case "linearhalved5"
										settings.coefficients = COEFF_LINEARHALVED5;
									case "moderatelongnew"
										settings.coefficients = COEFF_MODERATELONGNEW;
									case "moderatenew"
										settings.coefficients = COEFF_MODERATENEW;
									case "halved5re30"
										settings.coefficients = COEFF_LINEARHALVED5REINIT30MIN;
									case "halved5re1d"
										settings.coefficients = COEFF_LINEARHALVED5REINIT1DAY;
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

								switch in.normalize_str
									case "no"
										settings.normalize = NORM_NO;
									case "max"
										settings.normalize = NORM_MAX;
									case "norm"
										settings.normalize = NORM_NORM;
									otherwise
										error (sprintf("normalize \"%s\" not recognized",in.normalize_str) );
								end

								%{FILES
								settings.simname = compute_simname(settings, in);
								settings.outfile = sprintf("%s.mdat",settings.simname);
								settings.logfile = sprintf("%s.log",settings.simname);
								settings.infile = sprintf("%s.in",settings.simname);
								settings.tokenfile = sprintf("%s.token",settings.simname);
								%}FILES

								if clean_tokens
									delete(settings.tokenfile);
								elseif ( !exist(settings.outfile) &&  !exist(settings.tokenfile) )...
										|| overwrite || parse

									if !parse
										% To avoid duplicate exectution
										[fid, msg] = fopen (settings.tokenfile, "w");
										if fid==-1
											printf("Error in writing file %s. Error is: %s",...
													settings.tokenfile, msg);
											quit
										else
											fputs (fid, "Running"); fclose (fid);
										end

										%{GENERATE popularity
										in.last_cdf_values = zeros(in.p,1);
										in.last_zipf_points = ones(in.p,1);
										harmonic_num_void = [];
										for j=1:in.p
											[cdf_value, harmonic_num] = ZipfCDF_smart(...
													in.last_zipf_points(j), 0, [], in.alpha(j),...
													harmonic_num_void, in.ctlg(j), 1:in.ctlg(j) 
													);
											in.last_cdf_values(j) = cdf_value;
											in.harmonic_num(j) = harmonic_num;
										end

										% To take into account the fact that only active objects generate
										% requests
										in.adjust_factor = 1.0/in.ONtime; 
										in.lambda_per_CP = in.lambda * in.adjust_factor ...
													.* in.req_proportion;
										%}GENERATE popularity

										%{ ESTIMATED RANK
											% We compute the ranks of objects that each CP estimates
											in.estimated_rank = [];
											in.messy_popularity = [];

											if in.know < Inf
												[obj_prob, harm_num] = ZipfPDF(in.alpha(j), ...
														in.ctlg(j), in.harmonic_num(j) );
												in.estimated_rank = zeros(in.p,max(in.ctlg) );
												in.messy_popularity = zeros(in.p,max(in.ctlg) );
												for j=1:in.p
													req_rate = obj_prob' * in.know * in.ctlg(j);
													reqs = poissrnd(req_rate);
													% displacer is needed in order to randomize the 
													% reciprocal order between objects having the same 
													% requests generated
													displacer = rand(size(reqs) ) * 0.3;
													[reqs_sorted, in.estimated_rank(j,:) ] = ...
															sort(reqs+displacer,"descend");
													in.messy_popularity(j,:) = ...
															obj_prob(in.estimated_rank(j,:) )';
												end
											end
										%} ESTIMATED RANK

									end


									function_name = [];
									switch method
										case "csda"
											function_name = "dspsa";
										case "dspsa_orig"
											function_name = "dspsa";
										case "opencache"
											function_name = "dspsa";
										case "optimum"
											function_name = "dspsa";
										case "optimum_nominal"
											function_name = "optimum_nominal";
										case "unif"
											function_name = "dspsa";
										case "declaration"
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
									printf("\n%s exists:%d or it is running:%d\n",...
											settings.outfile, ...
											exist(settings.outfile), exist(settings.tokenfile) ) ;
							
								end

							end%boost for
							end%methods for
						end%projection
						end%coefficient end
						end%normalize for
						end%ONtime for
						end%ONOFFspan for
					end%K for
				end%lambda for
			end%T for
			end%know (knowledge degree values)
			end%tot_time for
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
