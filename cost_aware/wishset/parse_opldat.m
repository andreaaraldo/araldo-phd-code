% ciao
function [MaxTotalCache, ObjectReachabilityMatrix, TrafficDemand, TransitPrice] = parse_opldat(inputfile)

	data = [];
	f=fopen(inputfile,"r");
	l = fgetl(f);
	while ischar(l)
		if !isempty(l) && !isequal(l(1:2),"//" ) %// is the comment marker
			extra = strsplit (l, "=");
			var_name = strtrim( extra{1} );
			string_representation = extra{2};
			data.(var_name) = extra{2};
		end
		l = fgetl(f);
	end
	fclose(f);

	% Parse scalars
		dimensions=[1,1];
		ignore_last = false;

		NumASes = str2matrix(data.NumASes, dimensions, ignore_last);
		NumObjects = str2matrix(data.NumObjects, dimensions, ignore_last);
		NumScenarios = str2matrix(data.NumScenarios, dimensions, ignore_last);
		CachePrice = str2matrix(data.CachePrice, dimensions, ignore_last);
		MaxCachePerBorderRouter = \
					str2matrix(data.MaxCachePerBorderRouter, dimensions, ignore_last);
		MaxCoreCache = str2matrix(data.MaxCoreCache, dimensions, ignore_last);
		MaxTotalCache = str2matrix(data.MaxTotalCache, dimensions, ignore_last);
	%

	% Parse arrays
		dimensions=[1,NumScenarios];
		ignore_last = false;
		RealizationProbabilities = \	
				str2matrix(data.RealizationProbabilities, dimensions, ignore_last);

		dimensions=[NumASes, NumObjects, NumScenarios];
		ignore_last = true;
		ObjectReachabilityMatrix = \
				str2matrix(data.ObjectReachabilityMatrix, dimensions, ignore_last);
	
		dimensions=[1, NumObjects, NumScenarios];
		ignore_last = true;
		TrafficDemand = str2matrix(data.TrafficDemand, dimensions, ignore_last);
	
		dimensions=[1, NumASes, NumScenarios];
		ignore_last = true;
		TransitPrice = str2matrix(data.TransitPrice, dimensions, ignore_last);
	%

	% Verify_correctness{
		if  RealizationProbabilities(1) != 1 || \
						sum( RealizationProbabilities) != 1
			error("Incorrect realization probabilities. Notice that this\
						parser works only if there is one possible scenario");
		end

		if !(MaxCachePerBorderRouter == MaxCoreCache && MaxCoreCache == MaxTotalCache)
			error("The hypotheis MaxCachePerBorderRouter == MaxCoreCache \
				&& MaxCoreCache == MaxTotalCache is not satisfied");
		end	
	% }Verify_correctness

end
