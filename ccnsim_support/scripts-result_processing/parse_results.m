% Run it with octave

% result processing
global severe_debug = true;
global ignore_simtime = false;
global ignore_lambda = false;


out_folder="/tmp/"; % where to put results
optimization_result_folder="~/shared_with_servers/icn14_runs/greedy_algo-NESSUNA";
resultdir="~/software/ccnsim/results/sim_vs_che";

id_rep_list=[1:11,15:20]; # list of seeds

priceratio_list={"10","1.111","1.25","1.429","1.667","2","2.5","3.333","5"};
priceratio_list={"10"};
priceratio_list={"1","10","100"};


% The decision policies that I want to plot
decision_list={"lce","fix0.01","costaware0.01","tailandrank","costprobtailperf","costprobtailcons"}; 
decision_list={"lce","fix0.1", "fix0.05", "fix0.01", "fix0.005", "fix0.001", "fix0.0001", "fix0.00001"};
decision_list={"lce","fix0.01","costaware0.01","costprobprodplain0.01", "costprobcoincorr0.5", "costprobcoinplain0.5", "costprobcoincorr0.1", "costprobcoinplain0.1","costprobcoincorr0.01", "costprobcoinplain0.01"};
decision_list={"lce","fix0.01","tailandrank","costaware0.01","costprobtailcons"};
decision_list={"costaware0.01"};

xi_list = {"0.01","0.025","0.05","0.075","0.25","0.50","0.75","1","1.25","1.50","1.75","2","3","5","8"};
xi_list = {"0.01","0.25","0.50","0.75","1","1.25","1.50","1.75","2"};
xi_list = {"1"};



weights_list={"0.5_0.25_0.25","0.333_0.333_0.334","0.25_0.25_0.5"};
weights_list={"0.333_0.333_0.334","0.5_0.25_0.25","0.25_0.25_0.5"};
weights_list={"0.333_0.333_0.334","0_0.25_0.75", "0_0.5_0.5", "0_0.75_0.25", "0.25_0_0.75", "0.25_0.25_0.5", "0.25_0.5_0.25", "0.25_0.75_0", "0.5_0.25_0.25", "0.5_0.5_0", "0.75_0_0.25", "0.75_0.25_0","0.5_0.5_0"};
weights_list={"0.333_0.333_0.334"};

alpha_list = {"0.8","1","1.2"};
alpha_list = {"1"};


% The time window in which the samples to evaluate the stabilization are collected
window_list = {"60"};
variance_list = {"0.05"};

lambda_list = {"1000"};

q_list={"0"};


% See select.m for all the possible metrics
metric_list={"cost_reduction_wrt_fix","cost_savings_wrt_fix", "potential_reduction_wrt_costprobtailcons", "cost_savings_wrt_fix", "potential_savings_wrt_costprobtailcons","cost_fraction","hit_on_node_0"};
metric_list={"hit_on_node_0"};


network_list={"cost_scenario","abilene_cost","geant_cost","level3_cost","dtelecom_cost","tiger_cost","ws"};
network_list={"cost_scenario"};

forwarding_list={"spr","nrr"};
forwarding_list={"nrr"};

replacement_="lru";

simtime_list = {"1800","18000","180000","1800000","9000000"};
simtime_list = {"1800000"};

csize_list = {"1e3"};
csize_to_write_list = csize_list;

ctlg_="1e5";
ctlg_to_write_=ctlg_;
fixed_variable_names_additional = {"window","variance","simtime", "network","weights",...
			"q", "forwarding","lambda","xi","alpha"};
x_variable_name = "priceratio";
z_variable_name = "decision"; % Over the columns



i = 1;


############################################
##### PARSE FILES ##########################
############################################
for idx_window = 1:length(window_list)
	for idx_variance = 1:length(variance_list)
		for idx_simtime =  1:length(simtime_list)
			simtime_ = simtime_list{idx_simtime};
			for idx_lambda = 1: length(lambda_list)
				lambda_ = lambda_list{idx_lambda};

				for idx_csize = 1:length(csize_list)
					csize_ = csize_list{idx_csize};
					csize_to_write = csize_to_write_list{ idx_csize};
					for alpha_idx = 1:length(alpha_list)
						for priceratio_idx = 1:length(priceratio_list)
							for decision_idx = 1:length(decision_list)
								for idx_xi = 1:length(xi_list)
									xi_ = xi_list{idx_xi};
									for idx_weight = 1:length(weights_list)
										weights_ = weights_list{idx_weight};
										for q_idx = 1:length(q_list)
											for id_forwarding = 1:length(forwarding_list)
												for id_network = 1:length(network_list)
													for id_rep_ = id_rep_list

														selection_tuple.priceratio = ...
																priceratio_list{priceratio_idx};
														selection_tuple.decision = ...
																decision_list{decision_idx};
														selection_tuple.xi = xi_;
														selection_tuple.forwarding = ...
																forwarding_list{id_forwarding};
														selection_tuple.replacement = replacement_;
														selection_tuple.alpha = alpha_list{alpha_idx};
														selection_tuple.q = q_list{q_idx};
														selection_tuple.ctlg = ctlg_;
														selection_tuple.csize = csize_;
														selection_tuple.id_rep = id_rep_;
														selection_tuple.network = network_list{id_network};
														selection_tuple.weights = weights_;
														selection_tuple.simtime = simtime_;
														selection_tuple.window = window_list{idx_window};
														selection_tuple.variance = ...
																variance_list{idx_variance};
														selection_tuple.lambda = lambda_;
														selection_tuple.metric_list = metric_list;

														parsed_ = select(selection_tuple, resultdir,...
															optimization_result_folder);

														parsed(i) = parsed_;
														i++;
													endfor % network loop
												endfor % forwarding loop
											endfor % seed loop
										endfor % q_loop
									endfor % weights loop
								endfor % xi loop
							endfor
						endfor
					endfor %alpha for
				endfor %csize for
			endfor % lambda
		endfor %simtime
	endfor % window
endfor % variance loop
scatter_plot(parsed);

##################################
### PREPARE DATA FOR PLOTTING ####
######### FUNCTION ###############
##################################
input_data.out_folder = out_folder;

input_data.priceratio_list = priceratio_list;
input_data.decision_list = decision_list; % The decision plocies that I want to plot
input_data.id_rep_list = id_rep_list; # list of seeds
input_data.alpha_list = alpha_list;
input_data.q_list = q_list;
input_data.xi_list = xi_list;
input_data.csize_list = csize_list;
input_data.csize_to_write_list = csize_to_write_list;

input_data.resultdir = resultdir;
input_data.metric_list = metric_list;

input_data.network_list = network_list;
input_data.forwarding_list = forwarding_list;
input_data.replacement_ = replacement_;
input_data.ctlg_ = ctlg_; 
input_data.ctlg_to_write_ = ctlg_to_write_;

input_data.fixed_variable_names_additional = fixed_variable_names_additional;
for idx_fixed_variable_additional = 1:length(fixed_variable_names_additional)
	temp = eval( [input_data.fixed_variable_names_additional{...
						idx_fixed_variable_additional},"_list"] ) ;

	%CHECK{
		if length(temp) != 1
			fixed_var_name = ...
				input_data.fixed_variable_names_additional{idx_fixed_variable_additional}
			values = temp
			error("Values of fixed variable MUST be unique")
		endif
	%}CHECK
	
	input_data.fixed_variable_values_additional{idx_fixed_variable_additional} = temp{1};
endfor

input_data.x_variable_name = x_variable_name;
input_data.x_variable_values = eval( [input_data.x_variable_name,"_list"] ) ;
input_data.z_variable_name = z_variable_name;
input_data.z_variable_values = eval( [input_data.z_variable_name,"_list"] ) ;

input_data.parsed = parsed;
metric_vs_x_variable(input_data);
