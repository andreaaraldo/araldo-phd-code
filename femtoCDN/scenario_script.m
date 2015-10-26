%script
global severe_debug = 1;
addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
mdat_folder = "data/rawdata";

methods_ = {"descent", "dspsa_orig","dspsa_enhanced","optimum"};
requestss = [1e3];
catalogs = [1e5];
Ks = [1e3]; %cache slots
settings.epochs = 10000;
seeds = 1 ;

for seed = seeds
	rand("state",seed);

	for catalog=catalogs
		in.alpha=[0.4; 0.8; 1; 1.2];
		in.N = length(in.alpha); %num CPs
		in.catalog=repmat(catalog, in.N, 1);

			if mod(in.N,2) != 0
				error("Only an even number of CPs are accepted")
			end

			zipf=[];
			for j=1:in.N
				zipf = [zipf; (ZipfPDF(in.alpha(j), in.catalog(j)) )'];
			end

		for requests=requestss
			in.R = repmat(requests/in.N, in.N, 1);

			in.lambda=[];
			for j=1:in.N
				in.lambda = [in.lambda;  zipf(j,:) .* in.R(j) ];
			end

			for K=Ks
				in.K = K;

				for i=1:length(methods_)
					method = methods_{i};
					settings.outfile = sprintf("%s/ctlg_%g-req_%g-K_%g-%s-seed_%d.mdat",...
						mdat_folder,catalog,requests, K, method, seed);

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
				end%methods for
			end%K for
		end%request for
	end%catalog for
end%seed for
