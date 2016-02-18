% y_exp are the observed frequences
function y_reconstruct = zipf_fitting(y_obs)
	y_obs = reshape(y_obs, length(y_obs), 1 );
	y_obs_clean = y_obs; y_obs_clean(y_obs==0) = [];
	logy_obs = log(y_obs);
	logy_obs_clean = log(y_obs_clean);
	x=(1:length(y_obs) )';
	x_clean = x; x_clean(y_obs==0) = [];
	logx = log(x);
	logx_clean = log(x_clean);
	X = [ones(length(x_clean),1), logx_clean];
	params = (pinv(X'*X))*X'*logy_obs_clean;
	logy_reconstruct = params(2)*logx + params(1);
	y_reconstruct = e .^ logy_reconstruct;
	y_reconstruct = reshape(y_reconstruct, size(y_obs));

end
