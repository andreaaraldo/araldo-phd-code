function [ sequence_of_requests ] = ZipfRng( number_of_requests, alpha, N )
	printf("Inside ZipfRng\n");
	 cdf = ZipfCDF(alpha, N);
	printf("CDF computed\n");
	 sequence_of_requests=unifrnd(0,1,number_of_requests,1);
 	printf("unifrnd computed\n");

	 for i = 1:number_of_requests
         % Implement binary search here to speedup execution
         sequence_of_requests(i) = min(1+N-sum(cdf >= sequence_of_requests(i) ), N);
	 end
	printf("End of ZipfRng\n");
	sequence_of_requests
	exit(0)
end

