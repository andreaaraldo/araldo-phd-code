function  new_delta_vc = normalize_delta_vc(old_delta_vc, normalize)
	global NORM_NO; global NORM_MAX; global NORM_NORM;

	if !any(old_delta_vc !=0 ) || normalize == NORM_NO
		new_delta_vc = old_delta_vc;
	elseif normalize == NORM_MAX
		new_delta_vc =  old_delta_vc / max(abs(old_delta_vc) );
	elseif normalize == NORM_NORM
		norma = sqrt(sum(old_delta_vc .** 2) );
		new_delta_vc = old_delta_vc / norma ;
	end
end