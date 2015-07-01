%%%%%%% THIS CODE IS OLD AND IT IS NO MORE USED
% called by launcher.bash
% 			seed is needed by wishset_algo
function y = run_wishset_algo(inputfile, outputdir, optimization_dimension, seed)
	error("THIS CODE IS OLD AND IT IS NO MORE USED. It is very strange that it has been called");
	[MaxTotalCache, ObjectReachabilityMatrix, TrafficDemand, TransitPrice] = parse_opldat(inputfile);

	y = wishset_algo(outputdir, ObjectReachabilityMatrix, TransitPrice, TrafficDemand,\
						MaxTotalCache, optimization_dimension, seed);

end
