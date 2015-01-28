function [ cdf ] = ZipfCDF( alpha, N )

	p = (1:N)'.^alpha;
	p = 1./p;

	normalization_const = sum(p);

	p = p / normalization_const;

	cdf = p;

	for i=2:N
	    cdf(i,1) = cdf(i-1,1)+cdf(i,1);
	end

end

