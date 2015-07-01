% Called by plot_cost_vs_hitratio.m and plot_cache_sizing.m
% Represent data in a table ready to be plotted
function y = print_table (out_filename, matrix, column_names, fixed_variables, fixed_variable_names, comment)
	global severe_debug

	% Some checks
	if severe_debug
		if length(column_names) != size(matrix, 2)
			matrix
			column_names
			disp("length(column_names)=");
			length(column_names)
			disp("size(matrix, 2)=");
			size(matrix, 2)
			error("Column names do not match with matrix columns");
		end

		if length(fixed_variables) != length(fixed_variable_names)
			length(fixed_variables)
			length(fixed_variable_names)
			error("Fixed variable names do not match with the fixed variables");
		end
	end
	% end of Some checks


							delimiter = " ";
							outfile = fopen(out_filename,"w");
							column_name_string = "";
							for i=1:length(column_names)
								column_name_string = cstrcat(column_name_string, strvcat(column_names{i} ), delimiter );
							end

							fixed_variable_string = "";
							for i=1:length(fixed_variables)
%								fixed_variable_names{i,1}
%								fixed_variables{i,1}
%								num2str(fixed_variables{i,1} )
								fixed_variable_string = strcat(fixed_variable_string, \
											fixed_variable_names{i,1},"=",num2str(fixed_variables{i,1}),\
											";\t");
							end


							header_old = save_header_format_string();
							header_new = strcat (comment, "\n# Fixed data are:\n# "\
										, fixed_variable_string \
										, "\n# Columns are:\n#" \
										, column_name_string, "\n"\
										);
							fprintf(outfile,"%s",header_new);
							fclose(outfile);
							dlmwrite(out_filename, matrix, delim=delimiter,"-append");
	disp(["Data have been written in ", out_filename])

end
