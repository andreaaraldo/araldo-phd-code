function [ rnd ] = ZipfRng( numRndValues, alpha, N )

	 cdf = ZipfCDF(alpha, N);
	 rnd=unifrnd(0,1,numRndValues,1);
	 
	 for i = 1:numRndValues
         % Implement binary search here to speedup execution
         rnd(i,1) = min(1+N-sum(cdf >= rnd(i,1)), N);
	 end

end

