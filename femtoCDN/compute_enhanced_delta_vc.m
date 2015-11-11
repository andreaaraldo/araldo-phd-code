function delta_vc = compute_enhanced_delta_vc(improvement, loose)
	[i_sorted, i_idx] = sort (improvement, "descend");
	[d_sorted, d_idx] = sort (loose, "ascend");

	N = length(improvement);
	s = 0; % Number of swaps
	do
		s++;
		gain = i_sorted(s) - d_sorted(s);
		gain
	until gain <= 0 || s > N
	delta_vc = zeros(N,1 );
	for z=1:s
		delta_vc(i_idx(z) ) = 1;
		delta_vc(d_idx(z) ) = -1;
	end
end
