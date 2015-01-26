% Hello
%seed = 3;
%rand('seed',seed);

global severe_debug = true;

output_file = "scenario.dat";

% Define an experiment

ases = [1, 2];
quality_levels = [0, 1, 2];
catalog_size = 100;
alpha = 1;
rate_per_quality = [0, 300, 3500]; % In Kpbs
cache_per_quality = [0 11.25 131.25 ]; % In Mbps
utility_ratio = 2;
ASes_with_users = [1,2];
server = 2;
total_requests = 1000;
arcs = "{<2, 1, 5e6>};";
max_storage_at_single_as = 551250; % IN Mpbs
max_cache_storage = max_storage_at_single_as; % IN Mpbs




objects = 1:catalog_size;

ASes = represent_in_opl( "ASes", ases, true, "set" )
Objects = represent_in_opl( "Objects", objects, true, "set" )
QualityLevels = represent_in_opl( "QualityLevels", quality_levels, true, "set" )
Arcs = sprintf("Arcs = %s\n", arcs)


zipf = generate_zipf(alpha, catalog_size);
requests_at_each_AS.obj = 1:catalog_size;
requests_at_each_AS.req_num = zipf.distr .* (total_requests / length(ASes_with_users) );
requests.ASes = ASes_with_users;
ObjRequests = sprintf("ObjRequests = { ");
for i = 1:length(ASes_with_users)
	as = ASes_with_users(i);
	for j = 1:catalog_size
		obj = requests_at_each_AS.obj(j);
		req_num = requests_at_each_AS.req_num(j);
		ObjRequests = sprintf("%s <%g,%g,%g>,",ObjRequests, as, obj, req_num);
	endfor
endfor
ObjRequests = sprintf("%s};",ObjRequests);
ObjRequests(length(ObjRequests)-2) = " ";
printf( "%s\n",ObjRequests);


RatePerQuality = represent_in_opl( "RatePerQuality", rate_per_quality, true, "array" )

CachePerQuality = represent_in_opl( "CachePerQuality", cache_per_quality, true, "array" )

utility_per_quality = [0, 1, utility_ratio];
UtilityPerQuality = represent_in_opl( "UtilityPerQuality", utility_per_quality, true, "array" )


% Each object is published by only one producer
objects_producer_mapping_per_objects = zeros(1,length(ases) );
objects_producer_mapping_per_objects(1, server) = 1;
objects_published_by_producers = repmat(objects_producer_mapping_per_objects, catalog_size, 1);
represent_in_opl( "ObjectsPublishedByProducers", objects_published_by_producers, false, "array" )


MaxCacheStorageAtSingleAS = sprintf( "MaxCacheStorageAtSingleAS = %g", max_storage_at_single_as)
MaxCacheStorage = sprintf( "MaxCacheStorageAtSingleAS = %g", max_cache_storage)
