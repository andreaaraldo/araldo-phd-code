function  new_delta_vc = normalize_delta_vc(old_delta_vc)
	if any(old_delta_vc)!=0
		norm_factor = 1.0/max(abs(old_delta_vc) );
		new_delta_vc = norm_factor * old_delta_vc;
	else
		new_delta = old_delta;
	end
end
