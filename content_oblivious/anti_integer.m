%
function theta = anti_integer(theta, p, K, sigma)
	error "INVALID"
	theta_orig = theta;
	difference = sum(theta)-K;
	if difference!=0
		difference
	end

	while any( floor(theta)==theta ) || any(theta<zeros(p, 1)) || sum(floor(theta) )+p/2 >K
		"\n\nSolving"
		theta = theta_orig;
		problematic_theta = theta'
		r = unifrnd(0, sigma/p);
		Delta = round(unidrnd(2,p/2,1) - 1.5);
		ordering = randperm(p/2);
		Delta2 = -Delta(ordering);
		Delta = [Delta; Delta2];
		theta = theta + Delta * r;
		proposition=theta'
	end
end
