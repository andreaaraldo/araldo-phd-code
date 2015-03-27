% q: probability to accept an incoming object
function [pHitChe, pHitCheAvg] = hit(P_zipf, lambda_obj, TC, q, 'policy')

	N = size(P_zipf, 2); % catalog size
	pHitChe = zeros(1, N);

	switch policy
		case 'LCE'
			for i=1:N
				pHitChe(1,i) = 1-exp(-lambda_obj(1,i)*TC);
			end

		case 'Unif'
			for i=1:N
				e_ = exp(-lambda_obj(1,i)*TC);
				pHitChe(1,i) = q * (1 - e_ ) / ( e_ + q * (1-e_) );
			end

		case 'MID'
			for i=1:N
				e_ = exp(-lambda_obj(1,i)*TC);
				e_2 = exp(-lambda_obj(1,i)*(TC/2) );
				pHitChe(1,i) = (1 - e_ ) / ( 1 - e_ - e_2 );
			end

		otherwise
			error("Policy not valid");
	end

	pHitCheAvg = mean(pHitChe(1,:));
end
