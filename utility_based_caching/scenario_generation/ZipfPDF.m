% Andrea: Inspired by  ZipfCDF of Michele
function [ pdf, harmonic_num ] = ZipfPDF( alpha, N )

	if N!= 0
		p = (1:N)'.^alpha;
		p = 1./p;

		normalization_const = sum(p);

		harmonic_num = 1/normalization_const;
		pdf = harmonic_num .* p;
	else
		pdf = 0;
		harmonic_num = [];
	end
end

