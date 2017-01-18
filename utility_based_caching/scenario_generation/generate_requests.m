function [ sequence_of_requests ] = generate_requests( number_of_requests, alpha, N )
	harmonic_num = []; % To force its recomputation
	pdf = (ZipfPDF(alpha, N, harmonic_num) )';
	sequence_of_requests = randsample_modified(N, number_of_requests, true, pdf);
	if number_of_requests-ceil(number_of_requests)!=0
		number_of_requests
		error "number of requests must be integer"
	end
end

