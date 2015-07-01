%ciao

error ("THIS SCRIPT IS QUITE OLD. TO PARSE RESULTS, USE ",...
	"ccnsim/scripts/result_processing/parse_results.m. It can manage also results ",...
	"coming from this greedy algorithm");





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
result_folder = "~/Dropbox/shared_with_servers/globecom14/globecom14_working_folder_ctlg1e7_total/optimization_output" % The data to plot will be taken from this folder
available_plots = {"cost_vs_hitratio", "cache_sizing"};
requested_plots = {"cost_vs_hitratio"};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% PARSE OUTPUT %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global severe_debug = true;

folders = ls(result_folder);
separators = " -_";

for i=1:size(folders,1)
	name_ = strtrim( folders(i,:) );
	name{i} = name_;
	elements = strsplit(name_, separators);
	optimization{i} = elements{1,3}; 	% "lfu" or "ideal"
	objective{i} = elements{1,4};		% "hitratio" or "cost"
	catalog_size(i) = str2num( elements{1,6} );
	cache_size(i) = str2num( elements{1,8} );
	price_ratio(i) = str2num( elements{1,10} );
	seed(i) = str2num( elements{1,12} );
	totaldemand(i) = str2num( elements{1,14} );
	alpha(i) = str2num( elements{1,16} );
	asprob1(i) = str2num( elements{1,18} ); % The probability that a generic object is reachable through link 1
	asprob2(i) = str2num( elements{1,19} );
	asprob3(i) = str2num( elements{1,20} );

	filename = strcat(result_folder,"/",name_,"/totalcost.csv");
	totalcost_filename = filename;
	if exist(filename,'file') 
		totalcost(i) = csvread (filename) ;
	else
		totalcost(i) = nan;
	end 

	filename = strcat(result_folder,"/",name_,"/hitratio.csv");
	hitratio_filename = filename;
	if exist(filename,'file') 
		hitratio(i) = csvread (filename) ;
	else
		hitratio(i) = nan;
	end

	filename = strcat(result_folder,"/",name_,"/core_router_cache_size.csv");
	core_filename = filename;
	if exist(filename,'file') 
		core_router_cache_size(i) = csvread (filename) ;
	else
		core_router_cache_size(i) = nan;
	end

	filename = strcat(result_folder,"/",name_,"/border_router_cache_sizes.csv");
	border_filename = filename;
	if exist(filename,'file') 
		border_router_cache_sizes = dlmread (filename,";");
		border_router_1_cache_size(i) = border_router_cache_sizes(1);
		border_router_2_cache_size(i) = border_router_cache_sizes(2);
		border_router_3_cache_size(i) = border_router_cache_sizes(3);
	else
		border_router_1_cache_size(i) = nan;
		border_router_2_cache_size(i) = nan;
		border_router_3_cache_size(i) = nan;
	end
end

as_probability = [0.5 0.5 0.5];
behaviour_list = {"ideal"};
catalog_size_list = [1e8];
cache_size_list = [1e2,1e3,1e4];
seed_list = 1:20;
alpha_list = [0.8,1.2];
totaldemand_list = [1e15];
price_ratio_list = 1:10;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% VERIFY OPTIMIZATION %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if severe_debug
	% Verify that the ideal models are better than the lfu model
	if any( ismember(behaviour_list, "ideal") ) && any( ismember(behaviour_list, "cost") )
		for alpha_ = alpha_list
			for totaldemand_ = totaldemand_list
				for catalog_size_ = catalog_size_list
					for seed_ = seed_list
						for cache_size_idx = 1:length(cache_size_list)
							cache_size_ = cache_size_list(cache_size_idx);
							idx_incomplete = cache_size == cache_size_ &  \
											seed == seed_ & catalog_size == catalog_size_ & \ 
											totaldemand == totaldemand_ & alpha == alpha_;
							behaviour_ = "ideal";
								idx = strcmp(optimization,behaviour_) & idx_incomplete;
								idx_hitratio = idx & strcmp(objective, "hitratio");
								idx_cost = idx & strcmp(objective, "cost");
								totalcost_optimizing_hitratio_ideal = totalcost(idx_hitratio);
								totalcost_optimizing_cost_ideal = totalcost(idx_cost);
								hitratio_optimizing_hitratio_ideal = hitratio(idx_hitratio);
								hitratio_optimizing_cost_ideal = hitratio(idx_cost);


							% end of ideal behaviour

							behaviour_ = "lfu";
								idx = strcmp(optimization,behaviour_) & idx_incomplete;
								idx_hitratio = idx & strcmp(objective, "hitratio");
								idx_cost = idx & strcmp(objective, "cost");
								totalcost_optimizing_hitratio_lfu = totalcost(idx_hitratio);
								totalcost_optimizing_cost_lfu = totalcost(idx_cost);
								hitratio_optimizing_hitratio_lfu = hitratio(idx_hitratio);
								hitratio_optimizing_cost_lfu = hitratio(idx_cost);
							% end of lfu behaviour
					
							if any(		ismember(requested_plots, "cost_vs_hitratio_ideal") && \
										ismember(requested_plots, "cost_vs_hitratio_lfu") )

								if any( totalcost_optimizing_cost_ideal > totalcost_optimizing_cost_lfu )
									error("lfu cost optimization is better than ideal optimization.\
											This is an error.");
								end

								rounding_error = 10^-13;
								if any( hitratio_optimizing_hitratio_lfu - 	hitratio_optimizing_hitratio_ideal > \
										rounding_error )

									cache_size_
									seed_
									catalog_size_
									totaldemand_
									alpha_
									error("lfu hitratio optimization is better than ideal optimization.\
											This is an error.");
								end
							end % of any plots ...

						end % cache size loop
					end % seed loop
				end % catalog size loop
			end % totaldemand
		end %alpha
	endif
endif

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% PLOTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any( ismember(requested_plots, "cost_vs_hitratio") )
	plot_cost_vs_hitratio( name, optimization, objective, cache_size, seed, catalog_size,\
									totaldemand, alpha,\
									core_router_cache_size, border_router_1_cache_size,\
									border_router_2_cache_size, price_ratio,totalcost, hitratio,\
									alpha_list, totaldemand_list, behaviour_list, catalog_size_list, \
									seed_list, cache_size_list, price_ratio_list, \
									as_probability, asprob1,asprob2,asprob3);
end

if any( ismember(requested_plots, "cache_sizing") )

	% The following lists represent the only data that I want to take into account	
	as_probability = [0.5 0.5 0.5];
	behaviour_list = {"ideal"};
	catalog_size_list = [1e7];
	cache_size_list = [1e3];
	seed_list = 1:40;
	alpha_list = [0.8, 1.2];
	totaldemand_list = [1e15];
	objective_list = {"cost"}; % can be "cost" or "hitratio"
	

	plot_cache_sizing( optimization, objective, cache_size, seed, catalog_size, totaldemand, \
								alpha, core_router_cache_size, border_router_1_cache_size,\
								border_router_2_cache_size, border_router_3_cache_size, price_ratio,\
								alpha_list, totaldemand_list, catalog_size_list, seed_list,\
								cache_size_list, behaviour_list, objective_list, \
								as_probability, asprob1,asprob2,asprob3);
end
