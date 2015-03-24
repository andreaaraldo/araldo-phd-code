function [pHitChe, pHitCheAvg] = che_LCE(P_zipf, lambda_obj, TC)

	N = size(P_zipf, 2)
	pHitChe = zeros(1, N);

	for i=1:N
		pHitChe(1,i) = 1-exp(-lambda_obj(1,i)*TC);
	end

	pHitCheAvg = mean(pHitChe(1,:));
end