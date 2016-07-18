function  new_ghat = normalize_ghat(old_ghat, normalize)
	global NORM_NO; global NORM_MAX; global NORM_NORM;

	if !any(old_ghat !=0 ) || normalize == NORM_NO
		new_ghat = old_ghat;
	elseif normalize == NORM_MAX
		error("Normalization is no more supported");
		new_ghat =  old_ghat / max(abs(old_ghat) );
	elseif normalize == NORM_NORM
		error("Normalization is no more supported");
		norma = sqrt(sum(old_ghat .** 2) );
		new_ghat = old_ghat / norma ;
	end
end
