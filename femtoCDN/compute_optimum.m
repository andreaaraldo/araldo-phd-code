function theta_opt = compute_optimum(p, frequencies, K)
	border=ones(p,1);
	border_frequencies = [];
	for j=1:p
		border_frequencies = [border_frequencies; frequencies(j, border(j)) ];
	end

	for i=1:K
		[new_value, idx] = max(border_frequencies);
		border(idx)++;
		border_frequencies(idx) =  frequencies(idx, border(idx)) ;
	end%for

	theta_opt = border .- ones(p,1);
end
