% Andrea: Inspired by  ZipfCDF of Michele
function [ pdf, harmonic_num ] = ZipfPDF( alpha, N, harmonic_num )

	if N!= 0
		p = (1:N)'.^alpha;
		p = 1./p;

		if length(harmonic_num) == 0
			normalization_const = sum(p);
			harmonic_num = 1/normalization_const;
		% else I do not need to recompute it again
		end

		pdf = harmonic_num .* p;
	else
		pdf = 0;
		harmonic_num = [];
	end
end

