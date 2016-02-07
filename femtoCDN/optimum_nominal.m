function [hit_ratio_improvement, value, theta] = optimum_nominal(in, settings, infile)
        if length(in)==0 && length(settings)==0
                load (infile);
		delete(infile);
        end


	% SETTINGS
	global severe_debug

	N = in.p;
	border=ones(N,1);
	border_lambdatau = [];
	for j=1:N
		border_lambdatau = [border_lambdatau; in.lambdatau(j, border(j)) ];
	end

	for i=1:in.K

		[new_value, idx] = max(border_lambdatau);
		border(idx)++;
		border_lambdatau(idx) =  in.lambdatau(idx, border(idx)) ;
	end%for

	theta = c = border .- ones(N,1);
	value = compute_value(in, c);


	%{HIT RATIO IMPROVEMENT
	vc_unif = repmat(in.K/N, N,1 ); 
	c_unif = floor(vc_unif);
	
	value_unif = compute_value(in, c_unif);
	hit_ratio_improvement = value - value_unif;
	if hit_ratio_improvement < -1e-5
		value_unif
		value
		error("The improvement cannot be negative");
	else
	printf("improvement %d %g %g %d %.1g %g %g %s %d %g %g %g\n",...
		N, in.overall_ctlg, in.ctlg_eps, in.ctlg_perm, in.K, in.alpha0, in.alpha_eps, in.req_str_inner, in.R_perm, value*100, value_unif*100, hit_ratio_improvement*100 );
	%}HIT RATIO IMPROVEMENT


	%{CHECK
	if severe_debug

		if sum(c) != in.K || sum(c_unif) != in.K
			c
			c_unif
			error("configuration is wrong")
		end
	end
	%}CHECK

	printf("\nNominal miss ratio=%g", 1-value);
	%{
	if settings.save_mdat_file
		save(settings.outfile);
		disp (sprintf("%s written", settings.outfile) );
	end
	printf("\nsuccess\n");
	%}
end%function
