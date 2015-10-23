%script
global severe_debug = 1;
addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");

methods_ = {"descent", "dspsa_orig","dspsa_enhanced","optimum"};
methods_ = {"optimum"};

	% INPUT PARAMETERS
	in.alpha=[0.5; 1.2];
	in.R = [1e6; 1e6 ];
	in.catalog=[1e4; 1e4];
	in.K = 1e2; %cache slots


	% SETTINGS
	settings.epochs = 1000;
	settings.exploration_effort = 1/100;

		in.N = length(in.alpha); %num CPs
		if mod(in.N,2) != 0
			error("Only an even number of CPs are accepted")
		end

		in.lambda=[];
		for j=1:in.N
			in.lambda = [in.lambda; (ZipfPDF(in.alpha(j), in.catalog(j)) )' .* in.R(j) ];
		end


for i=1:length(methods_)
	method = methods_{i};
	settings.outfile = sprintf("%s-%g_req.mdat",method,sum(in.R) );

	switch method
		case "descent"
			cumulative_steepest_descent(in, settings);

		case "dspsa_orig"
			settings.enhanced = false;
			dspsa(in, settings);

		case "dspsa_enhanced"
			settings.enhanced = true;
			dspsa(in, settings);

		case "optimum"
			optimum(in,settings);

		otherwise
			method
			error("method not recognised");
	end%switch

	disp (sprintf("%s written", settings.outfile) );
end
