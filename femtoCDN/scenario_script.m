%The algoritm implemented here is inspired by
% Megory-Cohen, Igal and Ela, Givat - "Dynamic Cache Partitioning by Modified Steepest Descent" 
global severe_debug = 1;
addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
%pkg load statistics;
%pkg load communications; % for randint


% INPUT PARAMETERS
in.alpha=[0.8; 1.2];
in.R = [1e6; 1e6 ];
in.catalog=[1e3; 1e3];
in.K = 1e1; %cache slots

% SETTINGS
settings.epochs = 1000;

	in.N = length(in.alpha); %num CPs
	if mod(in.N,2) != 0
		error("Only an even number of CPs are accepted")
	end

	in.lambda=[];
	for j=1:in.N
		in.lambda = [in.lambda; (ZipfPDF(in.alpha(j), in.catalog(j)) )' .* in.R(j) ];
	end

%"cumulative_steepest_descent"
%cumulative_steepest_descent(in, settings)
"dspsa"
dspsa(in, settings)
