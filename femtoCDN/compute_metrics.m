function [hist_allocation, hist_cum_observed_req, hist_cum_hit] =...
		compute_metrics(in, settings, hist_theta, hist_num_of_misses, hist_tot_requests)

	CP_to_depict = 1;
	hist_allocation=hist_theta(CP_to_depict,:)/in.K;
	
	hist_cum_num_of_misses = zeros(in.p,settings.epochs+1); 
	for t=1:settings.epochs
		hist_cum_num_of_misses(:,t+1) = hist_cum_num_of_misses(:,t) + hist_num_of_misses(:,t); 
	endfor;
	hist_cum_tot_requests = zeros(in.p,settings.epochs+1); 
	for t=1:settings.epochs; 
		hist_cum_tot_requests(:,t+1) = hist_cum_tot_requests(:,t) + hist_tot_requests(:,t); 
	endfor;
	hist_cum_observed_req = sum(hist_cum_tot_requests,1);
	hist_cum_hit = 1- sum(hist_cum_num_of_misses,1) ./ hist_cum_observed_req; 

end
