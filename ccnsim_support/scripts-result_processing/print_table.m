% Called by plot_cost_vs_hitratio.m and plot_cache_sizing.m
% Represent data in a table ready to be plotted
function y = print_table (out_filename, matrix, x_variable_column, column_names, fixed_variables, fixed_variable_names, comment)
	global severe_debug

	% Some checks{
		if severe_debug
			if length(column_names) != size(matrix, 2)
				matrix
				column_names
				disp("length(column_names)=");
				length(column_names)
				disp("size(matrix, 2)=");
				size(matrix, 2)
				disp(["Error writing the file ",out_filename]);
				error("Column names do not match with matrix columns");
			end

			if length(fixed_variables) != length(fixed_variable_names)
				length(fixed_variables)
				length(fixed_variable_names)
				disp(["Error writing the file ",out_filename]);
				error("Fixed variable names do not match with the fixed variables");
			end

			if !isequal( zeros(size(matrix,1),1) , matrix(:,1) )
				matrix
				error("The first column of the matrix must be zeros");
			end
		end
	% }Some checks

	% DELETE PREVIOUS COPY{
		command = ["rm --force ",out_filename];
		[status, output] = system(command,1);
		if exist(out_filename,'file') 
			out_filename
			error("out_filename was not really removed");
		end
	% }DELETE PREVIOUS COPY

	delimiter = " ";
	 [outfile, msg]  = fopen(out_filename,"w");
	% CHECK{
	if (outfile < 0)
		out_filename
		msg
		error(["Error writing file. Check if the containing directory exists "]);
	endif
	% }CHECK

	column_name_string = "";
	for i=1:length(column_names)
			column_name_string = cstrcat(column_name_string, strvcat(column_names{i} ), delimiter );
	end

	fixed_variable_string = "";
	for i=1:length(fixed_variables)
		fixed_variable_name = fixed_variable_names{i};
		fixed_variable_value = fixed_variables{i};

		% CHECK{
			if severe_debug
				if length(fixed_variable_name) == 0
					fixed_variable_name
					error("fixed variable is invalid");
				endif

				if !isequal( class(fixed_variable_name), "char") && !isequal( class(fixed_variable_value), "char" )
					fixed_variable_name
					fixed_variable_value
					error("fixed variable is invalid");
				endif

			endif
		% }CHECK

								fixed_variable_string = strcat(fixed_variable_string, ...
											fixed_variable_name,"=",fixed_variable_value	,...
											";\t");
								% CHECK{
								if severe_debug && !isequal( class(fixed_variable_string), "char")
									i_th_fixed_variable_name = fixed_variable_names{i}
									i_th_fixed_variable = fixed_variables{i}{1}
									fixed_variable_string
									class_of_header_new = class(fixed_variable_string)
									error("Wrong format of fixed_variable_string");
								endif
								% }CHECK

							end


							header_old = save_header_format_string();
							header_new = strcat (comment, "\n# Fixed data are:\n# "...
										, fixed_variable_string ...
										, "\n# Columns are:\n#" ...
										, column_name_string, "\n"...
										);

							% CHECK{
							if severe_debug && !isequal( class(header_new), "char")
								header_new
								class_of_header_new = class(header_new)
								error("Wrong format of header new");
							endif
							% }CHECK

							fprintf(outfile,"%s",header_new);
							fclose(outfile);

%	dlmwrite(out_filename, matrix, delim=delimiter,"-append");
	dlmwrite("/tmp/table.txt", matrix(:,2:size(matrix,2) ), delim=delimiter);
	fid = fopen("/tmp/x_column.txt",'w');
		for idx_x = 1 :length(x_variable_column)
			x_value = x_variable_column{idx_x}	;
			fprintf(fid,"%s\n",x_value );
		endfor
	fclose(fid);

	command=["paste /tmp/x_column.txt /tmp/table.txt > /tmp/complete.txt"];
	[status, output] = system(command,1);

	command=["cat /tmp/complete.txt >> ", out_filename];
	[status, output] = system(command,1);

	disp(["Data have been written in ", out_filename])

end
