addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");

outfile="/tmp/profile.dat";
numOfObjects = 1e8 / 4;
numOfClasses = numOfObjects;
lambda=25; %req/s
Ts=[1 10 100]; %Observation time
zipf_alpha = 0.8;
results = [];
for T = Ts
	numOfRequestsSampled = lambda * T;
	[ numOfRequestsPerClass, numOfRequestsPerObj ] = zipf_realization( numOfObjects, numOfClasses, numOfRequestsSampled, zipf_alpha );
	results = [results,numOfRequestsPerObj/sum(numOfRequestsPerObj)];
endfor
harmonic_num=[];
results = [results, ZipfPDF( zipf_alpha, numOfObjects, harmonic_num )];
miss_profiles = cumsum(results, 1);
dlmwrite(outfile,miss_profiles, " ");
printf("%s written\n", outfile) ;
