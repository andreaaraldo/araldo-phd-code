% Andrea: Inspired by  ZipfCDF of Michele
function [ pdf ] = ZipfPDF( alpha, N )

	p = (1:N)'.^alpha;
	p = 1./p;

	normalization_const = sum(p);

	pdf = p / normalization_const;

end

