function corrected_vc = correct_vc(old_vc, in)
	corrected_vc = old_vc;

	% Guarantee that each CP has at least 1 cache slot
	while ( any( round(corrected_vc) < ones(in.N,1) ) )
		lucky = max(find( round(corrected_vc) < ones(in.N,1)) );
		unlucky_candidates = find( round(corrected_vc) > ones(in.N,1) );
		unlucky = unlucky_candidates( unidrnd( length(unlucky_candidates) ) );
		corrected_vc(unlucky) = corrected_vc(unlucky ) - 1;
		corrected_vc(lucky) = corrected_vc(lucky)+1;
	end

	difference = sum(round(corrected_vc) ) - in.K;
	for d=1:difference
		unlucky_candidates = find( round(corrected_vc)>1 );
		unlucky = unlucky_candidates(unidrnd( length(unlucky_candidates) ) );
		corrected_vc(unlucky) = corrected_vc(unlucky ) - 1;
	end

	while (difference<0)
		lucky = unidrnd(in.N);
		corrected_vc(lucky) = corrected_vc(lucky ) + 1;
		difference++;
	end
end
