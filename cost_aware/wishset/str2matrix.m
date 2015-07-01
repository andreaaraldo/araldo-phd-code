%ciao
function matrix = str2matrix(inputstring, dimensions, ignore_last)
	matrix_str = inputstring;
	matrix_str( matrix_str == "[" ) = " ";
	matrix_str( matrix_str == "]" ) = " ";
	matrix_str( matrix_str == " " ) = " ";
	matrix_str( matrix_str == ";" ) = " ";
	matrix_str = strtrim(matrix_str);
	matrix_str = strsplit (matrix_str, " ");
	matrix_str = cellfun(@str2num, matrix_str, 'UniformOutput', false);
	vector = cell2mat(matrix_str);

	if ignore_last
		step = dimensions( length(dimensions) );
		vector( step:step:length(vector ) ) = [];
		dimensions(length( dimensions) ) = [];
	end
	matrix = reshape(vector, shift(dimensions,1) )';

end
