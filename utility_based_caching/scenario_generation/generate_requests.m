function [ sequence_of_requests ] = generate_requests( number_of_requests, alpha, N )
	pdf = (ZipfPDF(alpha, N) )';
	sequence_of_requests = randsample_modified(N, number_of_requests, true, pdf);
end

