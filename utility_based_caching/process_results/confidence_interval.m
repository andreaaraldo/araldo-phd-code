% Compute the confidence interval of the matrix mar. 
% If dim == 1, one confidence interval will be computed for each column. This is useful when each row 
% 		of the matrix corresponds to a seed
% If dim == 2, onem confidence interval will be computed for each row. This is useful when each column
% 		of the matrix corresponds to a seed
function ye = confidence_interval_base(matr, dim, ignore_NaN)
	pkg load statistics;
	opt = 0; % see http://www.gnu.org/software/octave/doc/interpreter/Descriptive-Statistics.html
	if (!ignore_NaN)
		ye = ( 1.96/sqrt( size(matr,dim) ) ) .* std(matr, opt, dim);
	else
		ye = ( 1.96/sqrt( sum( !isnan(matr),dim) ) ) .* nanstd(matr, opt, dim);
	endif
end
