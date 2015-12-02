function  new_delta_vc = normalize_delta_vc(old_delta_vc)
	global NORM_NO; global NORM_MAX; global NORM_NORM;

	if !any(old_delta_vc !=0 ) || settings.normalize == NORM_NO
		new_delta_vc = old_delta_vc;
	elseif settings.normalize == NORM_MAX
		norm_factor = 
		new_delta_vc =  old_delta_vc / max(abs(old_delta_vc) );
	elseif settings.normalize == NORM_NORM
		norm_factor = 
		new_delta_vc = old_delta_vc / vectorNorm(old_delta_vc) ;
	end
end
