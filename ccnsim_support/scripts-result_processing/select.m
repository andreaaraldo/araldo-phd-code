% ciao
function parsed = select(selection_tuple, resultdir, optimization_result_folder)
	global severe_debug
	global ignore_simtime
	global ignore_lambda

						priceratio_ = selection_tuple.priceratio;
						decision_ = selection_tuple.decision;
						xi_ = selection_tuple.xi;
						network_ = selection_tuple.network;
						forwarding_ = selection_tuple.forwarding;
						replacement_ = selection_tuple.replacement;
						alpha_ = selection_tuple.alpha;
						q_ = selection_tuple.q;
						ctlg_ = selection_tuple.ctlg;
						csize_ = selection_tuple.csize;
						id_rep_ = selection_tuple.id_rep;
						network = selection_tuple.network;
						weights_ = selection_tuple.weights;
						simtime_ = selection_tuple.simtime;
						lambda_ = selection_tuple.lambda;
						window_ = selection_tuple.window;
						variance_ = selection_tuple.variance;

						metric_list = selection_tuple.metric_list;
						

						if isequal(csize_, "0")
							selection_tuple
							error("ciao");
						endif

						decision_root_ = "";
						if strmatch( "fix", decision_ )
							decision_root_ = "fix";
							target_decision_probability_ = ...
								num2str( strrep(decision_,"fix","") );

						elseif strmatch("costopt", decision_)
							decision_root_ = "costopt";
							target_decision_probability_ = NaN;

						elseif strmatch( "costaware", decision_ )
							decision_root_ = "costaware";
							target_decision_probability_ = ...
								num2str( strrep(decision_,"costaware","") );
						

						elseif length(decision_) >= 16

							if strmatch( "costprobprodplain", decision_)
								decision_root_ = "costprobprodplain";
								target_decision_probability_ = ...
									num2str( strrep(decision_,"costprobprodplain","") );

							elseif strmatch( "costprobcoinplain", decision_ )
								decision_root_ = "costprobcoinplain";
								target_decision_probability_ = ...
									num2str( strrep(decision_,"costprobcoinplain","") );

							elseif strmatch( "costprobcoincorr", decision_ )
								decision_root_ = "costprobcoincorr";
								target_decision_probability_ = ...
									num2str( strrep(decision_,"costprobcoincorr","") );

							elseif strmatch( "costprobtailperf", decision_ )
								error("Are you sure you want to use costprobtailperf.",...
									" It has been proved to be bad. Use costprobtailcons, instead");
								decision_root_ = "costprobtailperf";
								target_decision_probability_ = NaN;

							elseif strmatch( "costprobtailcons", decision_ )
								decision_root_ = "costprobtailcons";
								target_decision_probability_ = NaN;

							elseif strmatch( "costprobtailsmart", decision_ )
								decision_root_ = "costprobtailsmart";
								target_decision_probability_ = ...
									num2str( strrep(decision_,"costprobtailsmart","") );
							endif
						else
							decision_root_ = decision_;
							target_decision_probability_ = NaN;
						endif

						% CHECK{
						if isequal(decision_root_,"")
							error(["Error in parsing the decision policy ",decision_]);
						endif
						% }CHECK

						if ignore_simtime == true
							error("You cannot ignore simtime");
						endif

						sim_folder_prefix = strcat(resultdir,"/variance-",variance_,"/window-",window_,...
								"/simtime-",simtime_,"/lambda-",lambda_);
						
						destination_folder = ...
							strcat(sim_folder_prefix, "/",...
							network,"/q-",q_,...
							"/F-",forwarding_,...
							"/D-",decision_,"/xi-",xi_,"/R-",replacement_,...
							"/alpha-",alpha_,"/ctlg-",ctlg_,...
							"/cachesize-",num2str(csize_),"/weights-",weights_,...
							"/priceratio-",priceratio_);

						filename = strcat(destination_folder,"/ccn-id", ...
										num2str(id_rep_),".sca");


						if isequal(decision_,"costopt")
							% This file does not exists yet
							create_ccnsim_representation(selection_tuple,...
								destination_folder, optimization_result_folder);
						endif

						
						% CHECK{
							fid = fopen(filename, "r");
							if fid < 0
								filename
								error("the file does not exist");
							endif
							fclose(fid);
						% CHECK{

						parsed.filename_list = filename;

						parsed.decision = decision_;
						parsed.decision_root = decision_root_;
						parsed.target_decision_probability = target_decision_probability_;
						parsed.xi = xi_;
						parsed.forwarding = forwarding_;
						parsed.network = network_;
						parsed.replacement = replacement_;
						parsed.alpha = alpha_;
						parsed.q = q_;
						parsed.ctlg = ctlg_;
						parsed.csize = csize_;
						parsed.priceratio = priceratio_;
						parsed.id_rep = id_rep_;
						parsed.weights = weights_;
						parsed.simtime = simtime_;
						parsed.lambda = lambda_;
						parsed.window = window_;
						parsed.variance = variance_;

						parsed.p_hit = NaN;
						if isequal( network_, "one_cache_scenario_3_links")
							[status, parsed.p_hit] = my_grep("p_hit\\[0\\] ", filename, true);
						else
							[status, parsed.p_hit] = my_grep("inner_hit ", filename, true);
						endif

					% STABILIZATION_TIME{
						parsed.stabilization_time = NaN;
						string_to_search="stabilization_time ";
						command = ["grep ","\"",string_to_search,"\""," ",filename," | awk \'{print $4}\' "];
						[status, output] = system(command,1);
						lines_in_output = length(findstr(output,"\n",0));
						if lines_in_output == 1
							parsed.stabilization_time = str2num(output);
						endif
						%CHECK{
							if lines_in_output > 1
								command
								output
								filename
								command_pre = ["grep ","\"",string_to_search,"\""," "]
								command_post = [command_pre,"\"",string_to_search,"\""," ",filename]
								error("Parsing error");
							endif
						%]CHECK
					% }STABILIZATION_TIME


					% HIT_ON_NODE_0{
						parsed.hit_on_node_0 = NaN;
						string_to_search="p_hit\\[0\\]";
						command = ["grep ","\"",string_to_search,"\""," ",filename," | awk \'{print $4}\' "];
						[status, output] = system(command,1);
						lines_in_output = length(findstr(output,"\n",0));
						%CHECK{
							if lines_in_output != 1
								command
								output
								filename
								command_pre = ["grep ","\"",string_to_search,"\""," "]
								command_post = [command_pre,"\"",string_to_search,"\""," ",filename]
								error("Parsing error");
							endif
						%]CHECK
						parsed.hit_on_node_0 = str2num(output);
					% }HIT_ON_NODE_0



						string_to_search="total_cost ";
						command = ["grep ","\"",string_to_search,"\""," ",filename," | awk \'{print $4}\' "];
						[status, output] = system(command,1);
						% CHECK{
							lines_in_output = length(findstr(output,"\n",0));
							if lines_in_output != 1
								command
								output
								filename
								command_pre = ["grep ","\"",string_to_search,"\""," "]
								command_post = [command_pre,"\"",string_to_search,"\""," ",filename]
								error("Parsing error");
							end
						% }CHECK
						parsed.total_cost = str2num(output);

					if any( cellfun(@isequal,metric_list, {"hdistance"} ) )
						string_to_search="hdistance ";
						command = ["grep ","\"",string_to_search,"\""," ",filename," | awk \'{print $4}\' "];
						[status, output] = system(command,1);
						parsed.hdistance = str2num(output);
					else
						parsed.hdistance = NaN;
					endif

					if !isequal(decision_,"costopt")
						string_to_search="downloads ";
						command = ["grep ","\"",string_to_search,"\""," ",filename," | awk \'{print $4}\' "];
						[status, output] = system(command,1);
						parsed.client_requests = str2num(output);
					else
						parsed.client_requests = NaN;
					endif



	% LINK LOAD COMPUTATION{
					% Find where the repositories are attached
					[status, repo_free_node] = my_grep("repo-0 ",filename, false);
					[status, repo_cheap_node] = my_grep("repo-1 ",filename, false);
					[status, repo_expensive_node] = my_grep("repo-2 ",filename, false);

					if !isequal(decision_,"costopt")
						[status, output] = my_grep(["repo_load\\[",repo_free_node,"\\]" ], filename,false);
						parsed.free_link_load = str2num(output);
						if size(parsed.free_link_load) == [0,0]
							parsed.free_link_load = 0;
						endif

						[status, output] = ...
								my_grep(["repo_load\\[",repo_cheap_node,"\\]" ], filename,false);
						parsed.cheap_link_load = str2num(output);
						if size(parsed.cheap_link_load) == [0,0]
							parsed.cheap_link_load = 0;
						endif


						[status, output] = ...
								my_grep(["repo_load\\[",repo_expensive_node,"\\]" ], filename,false);
						parsed.expensive_link_load = str2num(output);
						if size(parsed.expensive_link_load) == [0,0]
							parsed.expensive_link_load = 0;
						endif
					else
						parsed.free_link_load = NaN;
						parsed.cheap_link_load = NaN;
						parsed.expensive_link_load = NaN;
					endif


		% CHECK{
			if severe_debug
				if (size(parsed.free_link_load) != [1,1] || ...
							size(parsed.cheap_link_load) != [1,1] ...
							||  size(parsed.expensive_link_load) != [1,1] )

							cheap_link_load_size = size(parsed.cheap_link_load)
							free_link_load = parsed.free_link_load
							cheap_link_load = parsed.cheap_link_load
							expensive_link_load = parsed.expensive_link_load
							error("Error in the link load computation");
				endif

				if size(parsed.total_cost) != [1,1]
					parsed.total_cost
					filename
					error("Error while parsing total_cost");
				endif
			endif
		% }CHECK
	% }LINK LOAD COMPUTATION



	if !isequal(decision_,"costopt")
		[status, decision_yes_vector] = my_grep("decision_yes\\[[0-9]*\\] ",filename,true);
		[status, decision_no_vector] = my_grep("decision_no\\[[0-9]*\\] ",filename,true);
		% The last 3 rows are relative to the fake nodes attached to the repos
		decision_yes_vector = decision_yes_vector(1:(length(decision_yes_vector)-3),:);
		decision_no_vector = decision_no_vector(1:(length(decision_no_vector)-3),:);
		decision_ratio_vector = decision_yes_vector ./ (decision_yes_vector+decision_no_vector);
		parsed.decision_yes = sum(decision_yes_vector);
		parsed.decision_no = sum(decision_no_vector);
		parsed.decision_ratio = mean(decision_ratio_vector);
	else
		parsed.decision_yes = NaN;
		parsed.decision_no = NaN;
		parsed.decision_ratio = NaN;
	endif


	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%% COMPARISON BASED METRICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% COMPUTE COST FRACTION{
		% Comparison with no-cache case
		parsed.cost_fraction = NaN;
		% Comparison with the no-cache scenario
		if (any( cellfun(@isequal,metric_list, {"cost_fraction"} ) ) || ...

			% The following 2 metrics depend on cost_fraction
			any( cellfun(@isequal,metric_list, {"potential_reduction_wrt_costprobtailcons"} ) )...
			|| any( cellfun(@isequal,metric_list, {"potential_reduction_wrt_costopt"} ) )...
			|| any( cellfun(@isequal,metric_list, {"cost_reduction_wrt_fix"} ) )
		)
			if isequal("costopt", decision_) && strcmp(csize_, "0")
				parsed.cost_fraction = 1;
			elseif isequal("costopt", decision_) && !strcmp(csize_, "0")
				selection_tuple_of_counterpart = selection_tuple;
				selection_tuple_of_counterpart.csize = "0";
				counterpart_parsed = select(selection_tuple_of_counterpart,...
						resultdir, optimization_result_folder);
				parsed.cost_fraction = parsed.total_cost / counterpart_parsed.total_cost;
			elseif !isequal("never", decision_)
				selection_tuple_of_never_counterpart = selection_tuple;
				selection_tuple_of_never_counterpart.decision = "never";
				selection_tuple_of_never_counterpart.xi = "1";
				never_counterpart_parsed = select(selection_tuple_of_never_counterpart,...
						resultdir, optimization_result_folder);
				parsed.cost_fraction = parsed.total_cost / never_counterpart_parsed.total_cost;
			endif
		endif

		% CHECK{
			if parsed.cost_fraction > 1
				filename
				cost_fraction = parsed.cost_fraction;
				error("Cost fraction cannot be greater then 1");
			endif
		% }CHECK
	% }COMPUTE COST FRACTION


	% COMPUTE COST_REDUCTION_WRT_FIX{
		parsed.cost_reduction_wrt_fix = NaN;
		if 	any( cellfun(@isequal,metric_list, {"cost_reduction_wrt_fix"} ) ) && ...
			isequal("costaware0.01",decision_)				

				selection_tuple_of_counterpart = selection_tuple;
				selection_tuple_of_counterpart.decision = "fix0.01";
				selection_tuple_of_counterpart.xi = "1";
				counterpart_parsed = select(selection_tuple_of_counterpart,...
						resultdir, optimization_result_folder);
				parsed.cost_reduction_wrt_fix = ...
						counterpart_parsed.cost_fraction - parsed.cost_fraction;

			% CHECK{
				if isnan(parsed.cost_reduction_wrt_fix)
					fix_cost_fraction = counterpart_parsed.cost_fraction
					our_cost_fraction = parsed.cost_fraction
					cost_reduction_wrt_fix = parsed.cost_reduction_wrt_fix
					errpr("Error in the cost_reduction calculation")
				end
			% }CHECK
		endif

	% }COMPUTE COST_REDUCTION_WRT_FIX


	% COMPUTE POTENTIAL_REDUCTION_WRT_COSTOPT{
		parsed.potential_reduction_wrt_costopt = NaN;
		if any( cellfun(@isequal,metric_list, {"potential_reduction_wrt_costopt"} ) ) &&...
					 !isequal("costopt", decision_) 

				selection_tuple_of_counterpart = selection_tuple;
				selection_tuple_of_counterpart.decision = "costopt";
				selection_tuple_of_counterpart.xi = "1";
				counterpart_parsed = select(selection_tuple_of_counterpart,...
						resultdir, optimization_result_folder);
				parsed.potential_reduction_wrt_costopt = ...
						parsed.cost_fraction - counterpart_parsed.cost_fraction;
		endif
	% }COMPUTE POTENTIAL_REDUCTION_WRT_COSTOPT


	% COMPUTE potential_reduction_wrt_costprobtailcons{
		parsed.potential_reduction_wrt_costprobtailcons = NaN;
		if any( cellfun(@isequal,metric_list, {"potential_reduction_wrt_costprobtailcons"} ) )...
				&& !isequal("costprobtailcons", decision_) 

				selection_tuple_of_counterpart = selection_tuple;
				selection_tuple_of_counterpart.decision = "costprobtailcons";
				selection_tuple_of_counterpart.metric_list={"cost_fraction"};
				selection_tuple_of_counterpart.xi = "1";
				counterpart_parsed = select(selection_tuple_of_counterpart,...
						resultdir, optimization_result_folder);
				parsed.potential_reduction_wrt_costprobtailcons = ...
						parsed.cost_fraction - counterpart_parsed.cost_fraction;
		endif
	% }COMPUTE potential_reduction_wrt_costprobtailcons


	% COMPUTE COST_SAVINGS_WRT_FIX{
		% Comparison with costopt
			parsed.cost_savings_wrt_fix = NaN;
			if any( cellfun(@isequal,metric_list, {"cost_savings_wrt_fix"} ) ) && ...
					strmatch("costaware", decision_root_)

				selection_tuple_of_fixed_counterpart = selection_tuple;
				selection_tuple_of_fixed_counterpart.decision =...
						 ["fix",target_decision_probability_];
				selection_tuple_of_fixed_counterpart.xi = "1";
				fixed_counterpart_parsed = select(selection_tuple_of_fixed_counterpart,...
						resultdir, optimization_result_folder);
				parsed.cost_savings_wrt_fix =...
					 (fixed_counterpart_parsed.total_cost - parsed.total_cost)/...
					fixed_counterpart_parsed.total_cost;
			endif
	% }COMPUTE COST_SAVINGS_WRT_FIX

	% COMPUTE POTENTIAL_SAVINGS_WRT_costprobtailcons{
		% Comparison with costopt
			parsed.potential_savings_wrt_costprobtailcons = NaN;
			if any(cellfun(@isequal,metric_list,{"potential_savings_wrt_costprobtailcons"} ) )...
					&& !isequal("costprobtailcons", decision_) 			

				selection_tuple_of_counterpart = selection_tuple;
				selection_tuple_of_counterpart.decision ="costprobtailcons";
				selection_tuple_of_counterpart.xi = "1";
				counterpart_parsed = select(selection_tuple_of_counterpart,...
						resultdir, optimization_result_folder);
				parsed.potential_savings_wrt_costprobtailcons = ...
					(parsed.total_cost - counterpart_parsed.total_cost)/...
					parsed.total_cost;
			endif
	% }COMPUTE POTENTIAL_SAVINGS_WRT_costprobtailcons

	% COMPUTE POTENTIAL_SAVINGS_WRT_COSTOPT{
			parsed.potential_savings_wrt_costopt = NaN;
			if any( cellfun(@isequal,metric_list, {"potential_savings_wrt_costopt"} ) )...
					&& !isequal("costopt", decision_) 			

				selection_tuple_of_counterpart = selection_tuple;
				selection_tuple_of_counterpart.decision ="costopt";
				selection_tuple_of_counterpart.xi = "1";
				counterpart_parsed = select(selection_tuple_of_counterpart,...
						resultdir, optimization_result_folder);
				parsed.potential_savings_wrt_costopt = ...
					(parsed.total_cost - counterpart_parsed.total_cost)/...
					parsed.total_cost;
			endif
	% }COMPUTE POTENTIAL_SAVINGS_WRT_COSTOPT

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


	% REPO_CARDINALITY{
		string_to_search="repo-0_card";
		command = ["grep ","\"",string_to_search,"\""," ",filename," | awk \'{print $4}\' "];
		[status, output0] = system(command,1);
		parsed.free_repo_cardinality = str2num(output0);

		string_to_search="repo-1_card";
		command = ["grep ","\"",string_to_search,"\""," ",filename," | awk \'{print $4}\' "];
		[status, output1] = system(command,1);
		parsed.cheap_repo_cardinality = str2num(output1);

		string_to_search="repo-2_card";
		command = ["grep ","\"",string_to_search,"\""," ",filename," | awk \'{print $4}\' "];
		[status, output2] = system(command,1);
		parsed.expensive_repo_cardinality = str2num(output2);

		% CHECK{
			lines_in_output0 = length(findstr(output0,"\n",0));
			lines_in_output1 = length(findstr(output1,"\n",0));
			lines_in_output2 = length(findstr(output2,"\n",0));
			if lines_in_output0 != 1 || lines_in_output1 != 1 || lines_in_output2 != 1
				output0
				output1
				output2
				filename
				error("Parsing error");
			end
		% }CHECK

	% }REPO_CARDINALITY


	% REPO_POPULARITY{
		string_to_search="repo_popularity\\[0\\]";
		command = ["grep ","\"",string_to_search,"\""," ",filename," | awk \'{print $4}\' "];
		[status, output0] = system(command,1);
		parsed.free_repo_popularity = str2num(output0);

		string_to_search="repo_popularity\\[1\\]";
		command = ["grep ","\"",string_to_search,"\""," ",filename," | awk \'{print $4}\' "];
		[status, output1] = system(command,1);
		parsed.cheap_repo_popularity = str2num(output1);

		string_to_search="repo_popularity\\[2\\]";
		command = ["grep ","\"",string_to_search,"\""," ",filename," | awk \'{print $4}\' "];
		[status, output2] = system(command,1);
		parsed.expensive_repo_popularity = str2num(output1);

		lines_in_output0 = length(findstr(output0,"\n",0));
		lines_in_output1 = length(findstr(output1,"\n",0));
		lines_in_output2 = length(findstr(output2,"\n",0));
		if lines_in_output0 != 1 || lines_in_output1 != 1 || lines_in_output2 != 1
			parsed.free_repo_popularity = parsed.cheap_repo_popularity = ...
			parsed.expensive_repo_popularity = NaN;
		end
		% }CHECK

	% }REPO_POPULARITY


	if ( size(parsed.p_hit)!=[1 1] )
		parsed.p_hit = NaN;
	endif
	# CHECK RESULTS{
	if ( size(parsed.total_cost)!=[1 1] || ...
				size(parsed.hdistance )!=[1 1] || size(parsed.client_requests)!=[1 1]...
				||size(parsed.cheap_link_load)!=[1 1] || ...
				size(parsed.expensive_link_load)!=[1 1] )

		p_hit = parsed.p_hit
		total_cost = parsed.total_cost
		hdistance = parsed.hdistance
		client_requests = parsed.client_requests
		cheap_link_load = parsed.cheap_link_load
		expensive_link_load = parsed.expensive_link_load
		priceratio_
		decision_
		command
		error("Parsing error");
	endif
	# }CHECK RESULTS
		
endfunction
