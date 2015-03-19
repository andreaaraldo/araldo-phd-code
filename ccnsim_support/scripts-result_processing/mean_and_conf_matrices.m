% metric_vs_priceratio
function y = mean_and_conf_matrices (input_data, single_metrix_matrix_over_seed_list, text_data, common_out_filename)
	global severe_debug;

	addpath("~/software/araldo-phd-code/general/process_results");

	metric_list = input_data.metric_list;
	x_variable_name = input_data.x_variable_name;
	x_variable_values = input_data.x_variable_values;
	z_variable_name = input_data.z_variable_name;
	z_variable_values = input_data.z_variable_values;
	out_folder = input_data.out_folder;

	x_variable_column = x_variable_values;



	fixed_variables = text_data.fixed_variables;
	fixed_variable_names = text_data.fixed_variable_names;
	comment = text_data.comment;

	column_names{1} = x_variable_name;
	for idx_z = 1:length(z_variable_values)
		column_names{ idx_z+1 } = z_variable_values{ idx_z };
	endfor


		% CHECK MATRIX{
					if severe_debug
						if size(single_metrix_matrix_over_seed_list,1) != length(x_variable_values) || size(single_metrix_matrix_over_seed_list,2) != length(column_names)
							fixed_variable_names_additional
							fixed_variable_values_additional
							x_variable_values
							single_metrix_matrix_over_seed_list
							metric = metric_list{idx_metric}
							error(["The number of rows in the matrix must be equal to the number of ",...
									"x variable.The number of columns must match the column names"]);
						endif
					endif
		% }CHECK MATRIX


		%{ COMPUTE MEAN AND CONF
			if length(size(single_metrix_matrix_over_seed_list) ) == 3
				dim = 3; % The seeds are varying along the 3rd dimension
				mean_matrix = mean(single_metrix_matrix_over_seed_list, dim);
				conf_matrix = confidence_interval(single_metrix_matrix_over_seed_list, dim);
			elseif length(size(single_metrix_matrix_over_seed_list) ) == 2
				% Only one seed is used
				mean_matrix = single_metrix_matrix_over_seed_list;
				conf_matrix = zeros(size(single_metrix_matrix_over_seed_list) );
			else
				matrix
				error("Dimension of matr is not correct")
			endif
		%} COMPUTE MEAN AND CONF

				% CHECK MATRIX{
					if severe_debug
						if size(mean_matrix,1) != length(x_variable_values) || size(conf_matrix,1) != length(x_variable_values) || size(mean_matrix,2) != length(column_names) || size(conf_matrix,2) != length(column_names)
							fixed_variable_names_additional
							fixed_variable_values_additional
							x_variable_values
							mean_matrix
							conf_matrix
							common_out_filename
							error(["The number of rows in the matrix must be equal to the number of ",...
									"x variable.The number of columns must match the column names"]);
						endif
					endif
				% }CHECK MATRIX

				% Print mean matrix
				matrix = mean_matrix;
				out_filename = [common_out_filename,"-mean.dat"];
				print_table(out_filename, matrix, x_variable_column, column_names, fixed_variables,fixed_variable_names, comment);

				% Print confidence interval matrix
				matrix = conf_matrix;
				out_filename = [common_out_filename,"-conf.dat"];
				print_table(out_filename, matrix, x_variable_column, column_names, fixed_variables,fixed_variable_names, comment);

endfunction
