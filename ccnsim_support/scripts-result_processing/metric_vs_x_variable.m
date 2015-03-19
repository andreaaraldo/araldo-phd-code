% metric_vs_priceratio
function y = metric_vs_x_variable (input_data)
	global severe_debug;

	% Unroll input data
	out_folder = input_data.out_folder;

	x_variable_name = input_data.x_variable_name;
	x_variable_values = input_data.x_variable_values;
	z_variable_name = input_data.z_variable_name;
	z_variable_values = input_data.z_variable_values;
	

	decision_list = input_data.decision_list; % The decision plocies that I want to plot
	id_rep_list = input_data.id_rep_list; # list of seeds
	alpha_list = input_data.alpha_list;
	csize_list = input_data.csize_list;
	csize_to_write_list = input_data.csize_to_write_list;

	resultdir = input_data.resultdir;
	metric_list = input_data.metric_list;

	network_list = input_data.network_list;
	forwarding_list = input_data.forwarding_list;
	replacement_ = input_data.replacement_;
	ctlg_ = input_data.ctlg_; 
	ctlg_to_write_ = input_data.ctlg_to_write_;

	fixed_variable_names_additional = input_data.fixed_variable_names_additional;
	fixed_variable_values_additional = input_data.fixed_variable_values_additional;
	

	filename_list = {input_data.parsed.filename_list};
	decision = {input_data.parsed.decision};
	xi = {input_data.parsed.xi};
	network = {input_data.parsed.network};
	forwarding = {input_data.parsed.forwarding};
	replacement = {input_data.parsed.replacement};
	alpha = {input_data.parsed.alpha};
	q = {input_data.parsed.q};
	ctlg = {input_data.parsed.ctlg};
	csize = {input_data.parsed.csize};
	priceratio = {input_data.parsed.priceratio};
	id_rep = {input_data.parsed.id_rep};
	p_hit = {input_data.parsed.p_hit};
	hit_on_node_0 = {input_data.parsed.hit_on_node_0};
	stabilization_time = {input_data.parsed.stabilization_time};
	total_cost = {input_data.parsed.total_cost};
	hdistance = {input_data.parsed.hdistance};
	client_requests = {input_data.parsed.client_requests};
	cheap_link_load = {input_data.parsed.cheap_link_load};
	expensive_link_load = {input_data.parsed.expensive_link_load};
	decision_yes = {input_data.parsed.decision_yes};
	decision_no = {input_data.parsed.decision_no};
	cost_fraction = {input_data.parsed.cost_fraction};
	cost_reduction_wrt_fix = {input_data.parsed.cost_reduction_wrt_fix};
	cost_savings_wrt_fix = {input_data.parsed.cost_savings_wrt_fix};
	potential_reduction_wrt_costopt = {input_data.parsed.potential_reduction_wrt_costopt};
	potential_reduction_wrt_costprobtailcons =...
				{input_data.parsed.potential_reduction_wrt_costprobtailcons};
	potential_savings_wrt_costprobtailcons = {input_data.parsed.potential_savings_wrt_costprobtailcons};
	potential_savings_wrt_costopt = {input_data.parsed.potential_savings_wrt_costopt};
	weights = {input_data.parsed.weights};
	simtime = {input_data.parsed.simtime};
	lambda = {input_data.parsed.lambda};
	window = {input_data.parsed.window};
	variance = {input_data.parsed.variance};



	% CHECK_INPUT_DATA{
		if severe_debug
			if length(fixed_variable_names_additional) != length(fixed_variable_values_additional)
				fixed_variable_names_additional
				fixed_variable_values_additional
				error("The two vectors must be equally long");
			endif
		endif

		if length(csize_list) != 1
			csize_list
			error("As for now, only a csize_list of length 1 is supported. If you want to ",...
					"use whatevere csize_list, please fix the loop below");
		endif
	% }CHECK_INPUT_DATA

	idx_pr_previous = ones(1,length(filename_list) );

	############################################
	##### MATRIX CONSTRUCTION ##################
	############################################
	for idx_csize = 1:length(csize_list)
		csize_ = csize_list{idx_csize};
		csize_to_write = csize_to_write_list{ idx_csize};

		seed_id = 1;

			# Initialize the matrix_over_seed{
				for idx_metric = 1:length(metric_list)
					matrix_over_seed_list{idx_metric} = [];
				endfor
			# }Initialize the matrix_over_seed

			for id_rep_ = id_rep_list
				# Compute the x_variable_column, using the first z_value
				z_value_ = z_variable_values{1};
				z_variable_assumed_values = eval(z_variable_name);
				idx_pr =  (strcmp(z_variable_assumed_values, z_value_ ) ...
							& ( cell2mat(id_rep) == id_rep_ ) ...
							& strcmp(csize, csize_) );

				% CHECK{
				if severe_debug
					if sum(idx_pr) < length(x_variable_values)
						x_variable_name
						x_variable_values
						idx_pr
						filename_list
						filenames_selected = filename_list{idx_pr}
						error(["The number of selected items MUST be at least",...
								" the lenght of x_variable_values"] );
					endif
				endif
				% }CHECK

				for idx_fixed_variable_additional = 1:length(fixed_variable_names_additional)
					% CHECK{
						if severe_debug
							if ! isscalar(fixed_variable_values_additional(idx_fixed_variable_additional) )
								fixed_values = ...
									fixed_variable_values_additional(idx_fixed_variable_additional)
								fixed_variable_name = ...
									fixed_variable_names_additional(idx_fixed_variable_additional)
								error("The fixed value MUST be a scalar");								
							endif
						endif
					% }CHECK

					value = fixed_variable_values_additional{idx_fixed_variable_additional};

					idx_pr_previous = idx_pr;
					values_assumed = ...
						eval(fixed_variable_names_additional(idx_fixed_variable_additional) );
					idx_pr = idx_pr ...
						& cellfun(@isequal, values_assumed, {value} );

					% CHECK{
						if severe_debug
							if ( sum(idx_pr == 1) == 0 )
								files_previously_selected =  ...
									filename_list( idx_pr_previous)
								variable_newly_considered = ...
									fixed_variable_names_additional{idx_fixed_variable_additional}
								values_of_that_variable = ...
									eval(fixed_variable_names_additional(...
											idx_fixed_variable_additional) )
								value_that_we_try_to_match = value
								files_currently_selected =  ...
									filename_list( idx_pr)
								error(["No results are matching when considering ",...
									variable_newly_considered]);
							endif
						endif % severe_debug
					% }CHECK
				endfor

				x_variable_column = x_variable_values;
				
				% CHECK{
					if severe_debug
						original_data = eval(x_variable_name);
						extracted_column = original_data(idx_pr) ;
						x_variable_column;
						if length(x_variable_column) != length(extracted_column) || ...
								 !isequal( x_variable_column, extracted_column )
							idx_pr_previous
							idx_pr
							x_variable_column
							extracted_column
							filenames = filename_list(idx_pr)
							original_data
							filtered_original_data = original_data(idx_pr)
							filtered_original_data_transformed = ...
								cellfun(@str2num, original_data(idx_pr) )
							error("x_variable_column and extracted_column_column MUST match");
						endif
					endif
				% }CHECK

				# For each seed, the first column of each matrix must be all zeros.
				# In print_table.m, it will be replaced with the real x column
				for idx_metric = 1:length(metric_list)
					metric_matrix_list{idx_metric} = zeros(length(x_variable_column),1);
				endfor

				for z_idx = 1:length(z_variable_values)
					z_value_ = z_variable_values{z_idx};

						z_variable_values_assumed = eval(z_variable_name);
						idx =  strcmp(z_variable_values_assumed, z_value_ ) ...
								& cell2mat(id_rep) == id_rep_...
								& strcmp(csize, csize_);

						if severe_debug && sum(idx ) == 0
							idx
							z_variable_values_assumed
							error("No results are going to be selected");
							
						endif


						idx_previous = [];
						for idx_fixed_variable_additional = 1:length(fixed_variable_names_additional)
							value = fixed_variable_values_additional{...
												idx_fixed_variable_additional};

							values_assumed = ...
								eval(fixed_variable_names_additional(...
										idx_fixed_variable_additional) );
							idx_previous = idx;
							idx = idx ...
								& cellfun(@isequal, values_assumed, {value} );

							% CHECK{
							if severe_debug
								if sum(idx) == 0
									fixed_var_name = fixed_variable_names_additional{...
											idx_fixed_variable_additional};
									error(["After considering ",fixed_var_name," no results are"...
										" selected.Are you sure that variable is intended to be fixed?"]);
								endif
							endif
							% }CHECK
						endfor
						
						# CHECK{
							if severe_debug
								original_data = eval(x_variable_name);
								x_variable_column_for_check = original_data(idx);
								if !isequal(x_variable_column_for_check,  x_variable_column )
									fixed_variable_name = fixed_variable_names_additional(...
										idx_fixed_variable_additional)
									values_assumed
									value_to_match = value
									class_of_value = class(value)
									idx
									idx_previous
									prova_riprova = cellfun(@isequal, values_assumed, {value} )
									x_variable_column_for_check
									x_variable_column
									selected_files = filename_list(idx)
									error("x_variable_column is erroneous");
								endif
							endif
						# }CHECK
						
						for idx_metric = 1:length(metric_list)
							column_list{idx_metric} = [];
							metric_name = metric_list{idx_metric};
		
							switch ( metric_name )
								case "p_hit"
									column_list{idx_metric} = cell2mat( p_hit(idx) );

								case "hit_on_node_0"
									column_list{idx_metric} = cell2mat( p_hit(idx) );

								case "total_cost"
									column_list{idx_metric} = cell2mat( total_cost(idx) );

								case "per_request_cost"
									column_list{idx_metric} = ...
										cell2mat( total_cost(idx) ) ./ cell2mat( client_requests(idx) );

								case "hdistance"
									column_list{idx_metric} = cell2mat( hdistance(idx) );

								case "expensive_link_utilization"
									column_list{idx_metric} = cell2mat( expensive_link_load(idx) ) ./ ...
											( cell2mat( expensive_link_load(idx) ) + ...
											  cell2mat( cheap_link_load(idx)) 	);

								case "client_requests"
									column_list{idx_metric} = cell2mat( client_requests(idx) );

								case "decision_ratio"
									column_list{idx_metric} = cell2mat( decision_yes(idx) ) ./ ...
											(	cell2mat( decision_yes(idx) ) + ...
												cell2mat( decision_no(idx) ));

						% COMPARISON BASED METRICS{
								case "cost_fraction"
									column_list{idx_metric} = cell2mat( cost_fraction(idx) );

								case "cost_savings_wrt_fix"
									column_list{idx_metric} = ...
											cell2mat( cost_savings_wrt_fix(idx) );

								case "cost_reduction_wrt_fix"
									column_list{idx_metric} = ...
											cell2mat( cost_reduction_wrt_fix(idx) );

								case "potential_reduction_wrt_costopt"
									column_list{idx_metric} = ...
											cell2mat( potential_reduction_wrt_costopt(idx) );

								case "potential_reduction_wrt_costprobtailcons"
									column_list{idx_metric} = cell2mat(...
											potential_reduction_wrt_costprobtailcons(idx) );

								case "potential_savings_wrt_costprobtailcons"
									column_list{idx_metric} = cell2mat(...
											potential_savings_wrt_costprobtailcons(idx) );

								case "potential_savings_wrt_costopt"
									column_list{idx_metric} = cell2mat(...
											potential_savings_wrt_costopt(idx) );

								case "stabilization_time"
									column_list{idx_metric} = cell2mat(...
											stabilization_time(idx) );
						% }COMPARISON BASED METRICS

								otherwise
									error(["metric ",metric_name," is not valid"]);
							endswitch

							# CHECK DIMENSIONS{
								if severe_debug
									if size(metric_matrix_list{idx_metric},1) != length(column_list{idx_metric})
										matrix = metric_matrix_list{idx_metric}
										column = column_list{idx_metric}
										x_variable_column_for_check
										decision_
										error("Length of column MUST be equal to the row number of matrix");
									endif

									if size(metric_matrix_list{idx_metric},1) != length(x_variable_values) || length(column_list{idx_metric} ) != length(x_variable_values)
										fixed_variable_names_additional
										fixed_variable_values_additional
										x_variable_values
										column_list{idx_metric}
										metric_matrix_list{idx_metric}
										error("The number of rows in the matrix and the lenghth of x_variable_column must be equal to the number of price ratios");
									endif
								endif
							# }CHECK DIMENSIONS

						endfor

					for idx_metric = 1:length(metric_list)
						% Add the column corresponding to decision_ to the matrices	
						metric_matrix_list{idx_metric} = ...
							[ metric_matrix_list{idx_metric}, column_list{idx_metric}' ];
						% The matrix above is related to one seed only
					endfor
				endfor % decision loop

				for idx_metric = 1:length(metric_list)
					% Going along the rows of p_hit_matrix_over_seed, the price_ratios are changing
					% Going along the comumns of p_hit_matrix_over_seed, the decision policies are changing
					% Going along the 3rd dimension of p_hit_matrix_over_seed, the seeds are changing
					matrix_over_seed_list{idx_metric} = cat( 3,...
							matrix_over_seed_list{idx_metric}, metric_matrix_list{idx_metric});
					
					% CHECK MATRIX{
					if severe_debug
						if size(matrix_over_seed_list{idx_metric},1) != length(x_variable_values)
							fixed_variable_names_additional
							fixed_variable_values_additional
							x_variable_values
							matrix_over_seed_list{idx_metric}
							disp( ["metric=", metric_list{idx_metric} ] );
							error("The number of rows in the matrix must be equal to the number of price ratios");
						endif
					endif
					% }CHECK MATRIX
				endfor

				seed_id ++;
			endfor # id_rep for

			% matrix_over_seed_list{idx_metric} is now complete

			% {PREPARING TEXTUAL DATA
			% Adding here the variables that never change
			fixed_variables = { replacement_; ctlg_; csize_; num2str(id_rep_list) };
			fixed_variable_names = {"replacement"; "ctlg";"csize"; "seed_list"};
			fix_var_num = length(fixed_variables);

			% CHECK{
			if severe_debug && fix_var_num != length(fixed_variable_names)
				fixed_variable_names
				fixed_variables
				error("fixed_variable_names and fixed_variables are different");
			endif
			% }CHECK


			for idx_fixed_variable_additional = 1:length(fixed_variable_names_additional)
				new_fix_var_name = fixed_variable_names_additional{idx_fixed_variable_additional};

				% CHECK{
					if severe_debug && length(new_fix_var_name)==0
						error("added a variable with null name");
					endif
				% }CHECK

				fixed_variables{ fix_var_num + idx_fixed_variable_additional } =...
							fixed_variable_values_additional{idx_fixed_variable_additional};

				fixed_variable_names{ fix_var_num + idx_fixed_variable_additional } =...
							new_fix_var_name;				
			endfor

			comment="";
			text_data.fixed_variables = fixed_variables;
			text_data.fixed_variable_names = fixed_variable_names;
			text_data.comment = comment;
			% }PREPARING TEXTUAL DATA

	endfor %csize

	for idx_metric = 1:length(metric_list)
			metric = metric_list{idx_metric};
			single_matrix_over_seed_list = matrix_over_seed_list{idx_metric};

			common_out_filename = [ out_folder, metric,"_vs_", x_variable_name];
			for idx_fixed_variable_additional = 1:length(fixed_variable_names_additional)
					value = fixed_variable_values_additional{idx_fixed_variable_additional};
					common_out_filename = [common_out_filename, "-",...
						fixed_variable_names_additional{idx_fixed_variable_additional}, "_", value...
						];
			endfor
			common_out_filename = [common_out_filename, "-ctlg_",ctlg_to_write_,"-csize_",csize_ ];
			% CHECK{
				if severe_debug && !isequal( class(common_out_filename), "char" )
						common_out_filename
						class_of_common_out_filename = class(common_out_filename)
						error("Error in the construction of the output file name");
				endif
			% }CHECK

			
			mean_and_conf_matrices(input_data, single_matrix_over_seed_list, text_data,...
				 common_out_filename);
	endfor

endfunction
