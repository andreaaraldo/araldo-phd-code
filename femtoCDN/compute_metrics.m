function [hist_allocation, hist_cum_observed_req, hist_cum_hit] =...
		compute_metrics(in, settings, hist_vc, hist_m, hist_f)

	hist_c = round(hist_vc);
	hist_allocation=hist_c(2,:)/in.K;
	
	hist_cum_m = zeros(in.N,settings.epochs+1); 
	for t=1:settings.epochs
		hist_cum_m(:,t+1) = hist_cum_m(:,t) + hist_m(:,t); 
	endfor;
	hist_cum_f = zeros(in.N,settings.epochs+1); 
	for t=1:settings.epochs; 
		hist_cum_f(:,t+1) = hist_cum_f(:,t) + hist_f(:,t); 
	endfor;
	hist_cum_observed_req = sum(hist_cum_f,1);
	hist_cum_hit = 1- sum(hist_cum_m,1) ./ hist_cum_observed_req; 

end
