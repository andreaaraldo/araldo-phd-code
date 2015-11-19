function parse_results(in, settings)
	mdatfile =  = sprintf("%s.mdat",settings.infile);
	outfilename = sprintf("%s.out",settings.infile);
	load(mdatfile);
	hist_value = [0];
	for t=1:settings.epochs;
		hist_value= [hist_value; compute_value(in, round(vc) ) ];
	end
	dlmwrite(outfilename,  [hist_cum_observed_req', round( hist_vc(1,:) )', hist_value ], " " );
	printf("%s written", outfilename);
end
