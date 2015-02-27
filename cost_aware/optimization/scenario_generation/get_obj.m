function obj = get_obj(rank_vec, requested_rank)
	x = requested_rank;
	idx = find(rank_vec == requested_rank);

	if length( idx ) != 1
		error([length( idx ) "were find with rank " x]);
	endif

	obj = rank_vec(idx);
endfunction
