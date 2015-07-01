% result processing
global severe_debug = true;

per_seed_results = false;
out_folder="~/Dropbox/shared_with_servers/icn14_runs/";

priceratio_list=[10];
probability_to_cache_list={"0.01", "0.02"}; % The decision plocies that I want to plot
xi_list = [1];
id_rep_list=1:3; # list of seeds
alpha_list = [0, 0.8, 1, 1.2];
csize_list = {"1000"};
csize_to_write_list = {"1000"};

resultdir="~/software/ccnsim/results";
metric_list = {"p_hit", "total_cost", "per_request_cost", "hdistance", "expensive_link_utilization",\
						"client_requests", "decision_ratio"};

network="one_cache_scenario";
forwarding_="nrr";
replacement_="lru";
ctlg_="10\\^5"; 
ctlg_to_write_="1e5";

fixed_variable_names_additional = {"priceratio", "xi"};
x_variable_name = "alpha";


i = 1;



disp("YOU SHOULD CHECK IF THE FILE EXISTS");
############################################
##### PARSE FILES ##########################
############################################
for idx_csize = 1:length(csize_list)
	csize_ = csize_list{idx_csize};
	csize_to_write = csize_to_write_list{ idx_csize};
	for alpha_ = alpha_list
		for priceratio_idx = 1:length(priceratio_list)
			for id_rep_ = id_rep_list
				decisionroot_list = {"fix","costprob"};
				for decision_idx = 1:length(decisionroot_list)
					for xi_ = xi_list
						priceratio_ = priceratio_list(priceratio_idx);
						decision_ = [decision_list{decision_idx},probability_to_cache_];

						filename = strcat(resultdir,"/",network,"/F-",forwarding_,"/D-",decision_,"/xi-",num2str(xi_),"/R-",replacement_,"/alpha-",num2str(alpha_),"/ctlg-",ctlg_,"/cachesize-",num2str(csize_),"/priceratio-",num2str(priceratio_),"/ccn-id",num2str(id_rep_),".sca");

						parsed.filename_list{i} = filename;

						parsed.decision{i} = decision_;
						parsed.xi(i) = xi_;
						parsed.forwarding{i} = forwarding_;
						parsed.replacement{i} = replacement_;
						parsed.alpha(i) = alpha_;
						parsed.ctlg{i} = ctlg_;
						parsed.csize{i} = csize_;
						parsed.priceratio(i) = priceratio_;
						parsed.id_rep(i) = id_rep_;

						[status, output] = system(command,1);
						parsed.p_hit{i} = str2num(output);
						string_to_search="total_cost ";
						command = ["grep ","\"",string_to_search,"\""," ",filename," | awk \'{print $4}\' "];
						[status, output] = system(command,1);
						parsed.total_cost{i} = str2num(output);

						# CHECK RESULTS{
							if ( size(parsed.p_hit{i})!=[1 1] || size(parsed.total_cost{i})!=[1 1] || \
								 size(parsed.hdistance{i} )!=[1 1] \
									|| size(parsed.client_requests{i})!=[1 1] || size(parsed.cheap_link_load{i})!=[1 1] \
									|| size(parsed.expensive_link_load{i})!=[1 1] )

								priceratio_
								decision_
								disp(["p_hit=", num2str(parsed.p_hit{i}), "; total_cost=", \
										num2str(parsed.total_cost{i}), "; hdistance=",num2str(parsed.hdistance{i} ), \
										"; client_requests=",num2str(parsed.client_requests{i} )] );
								command
								error("Parsing error");
							endif
						# }CHECK RESULTS

						i++;
					endfor % seed loop
				endfor % xi loop
			endfor
		endfor
	endfor %alpha for
endfor %csize for


##################################
### PREPARE DATA FOR PLOTTING ####
######### FUNCTION ###############
input_data.out_folder = out_folder;

input_data.priceratio_list = priceratio_list;
input_data.possible_decisions = possible_decisions;
input_data.decision_list = decision_list; % The decision plocies that I want to plot
input_data.id_rep_list = id_rep_list; # list of seeds
input_data.alpha_list = alpha_list;
input_data.xi_list = alpha_list;
input_data.csize_list = csize_list;
input_data.csize_to_write_list = csize_to_write_list;

input_data.resultdir = resultdir;
input_data.metric_list = metric_list;

input_data.network = network;
input_data.forwarding_ = forwarding_;
input_data.replacement_ = replacement_;
input_data.ctlg_ = ctlg_; 
input_data.ctlg_to_write_ = ctlg_to_write_;

input_data.fixed_variable_names_additional = fixed_variable_names_additional;
for idx_fixed_variable_additional = 1:length(fixed_variable_names_additional)
	input_data.fixed_variable_values_additional{idx_fixed_variable_additional} = \
			eval( [input_data.fixed_variable_names_additional{idx_fixed_variable_additional},"_list"] );
endfor

input_data.x_variable_name = x_variable_name;
input_data.x_variable_values = eval( [input_data.x_variable_name,"_list"] ) ;

input_data.parsed = parsed;





metric_vs_x_variable(input_data);
