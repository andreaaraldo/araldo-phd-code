function [ sequence_of_requests ] = generate_requests( number_of_requests, alpha, N )
	harmonic_num = []; % To force its recomputation
	pdf = (ZipfPDF(alpha, N, harmonic_num) )';
	sequence_of_requests = randsample_modified(N, number_of_requests, true, pdf);
end

