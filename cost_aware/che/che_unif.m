% q: probability to accept an incoming object
function [pHitChe, pHitCheAvg] = che_unif(P_zipf, lambda_obj, TC, q)

	N = size(P_zipf, 2)
	pHitChe = zeros(1, N);

	for i=1:N
		e_ = exp(-lambda_obj(1,i)*TC);
		pHitChe(1,i) = q * (1 - e_ ) / ( e_ + q * (1-e_) );
	end

	pHitCheAvg = mean(pHitChe(1,:));
end
