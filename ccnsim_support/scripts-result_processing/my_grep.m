% ciao
function [status, output] = my_grep(string_to_search, filename, convert)

	command = ["grep ","\"",string_to_search,"\""," ",filename," | awk \'{print $4}\' "];
	[status, output] = system(command,1);
	output = strtrim(output);

	if convert == true
		output = str2num(output);
	endif

endfunction
