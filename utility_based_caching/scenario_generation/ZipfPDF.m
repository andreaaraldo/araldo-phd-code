% Andrea: Inspired by  ZipfCDF of Michele
function [ pdf ] = ZipfPDF( alpha, N )

	if N!= 0
		p = (1:N)'.^alpha;
		p = 1./p;

		normalization_const = sum(p);

		pdf = p / normalization_const;

	else
		pdf = 0;
	end
end

