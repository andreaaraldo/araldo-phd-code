function optimum(in, settings, infile)
        if length(in)==0 && length(settings)==0
                load (infile);
        end


	% SETTINGS
	global severe_debug

	N = in.N;
	border=ones(N,1);
	border_lambda = [];
	for j=1:N
		border_lambda = [border_lambda; in.lambda(j, border(j)) ];
	end

	for i=1:in.K

		[new_value, idx] = max(border_lambda);
		border(idx)++;
		border_lambda(idx) =  in.lambda(idx, border(idx)) ;
	end%for

	c = border .- ones(N,1);
	value = compute_value(in, c);

	save(settings.outfile);
        disp (sprintf("%s written", settings.outfile) );
end%function
