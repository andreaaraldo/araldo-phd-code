function hist_infty_err = compute_hist_infty_err(theta_opt, hist_theta)
	hist_difference = ( hist_theta - repmat(theta_opt,1, size(hist_theta,2)) );
	hist_infty_err = norm(hist_difference, Inf,"cols");
end
