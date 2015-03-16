% Compute the confidence interval of the matrix mar. 
% If dim == 1, one confidence interval will be computed for each column. This is useful when each row 
% 		of the matrix corresponds to a seed
% If dim == 2, onem confidence interval will be computed for each row. This is useful when each column
% 		of the matrix corresponds to a seed
function ye = confidence_interval_base(matr, dim)
	error ("This is an old function. Use ~/software/araldo-phd-code/general/process_results/confidence_interval.m instead");
	opt = 0; % see http://www.gnu.org/software/octave/doc/interpreter/Descriptive-Statistics.html
	ye = ( 1.96/sqrt( size(matr,dim) ) ) .* std(matr, opt, dim);
end
