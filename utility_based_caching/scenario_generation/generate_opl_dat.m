%Ciao
function generate_opl_dat(ases, quality_levels, catalog_size, alpha, rate_per_quality, 
			cache_per_quality, utility_ratio, ASes_with_users, server, total_requests,
			arcs, max_storage_at_single_as, max_cache_storage)

	filename = "scenario.dat";
	objects = 1:catalog_size;

	ASes = represent_in_opl( "ASes", ases, true, "set" );
	Objects = represent_in_opl( "Objects", objects, true, "set" );
	QualityLevels = represent_in_opl( "QualityLevels", quality_levels, true, "set" );
	Arcs = sprintf("Arcs = %s\n", arcs);


	zipf = generate_zipf(alpha, catalog_size);
	requests_at_each_AS.obj = 1:catalog_size;
	requests_at_each_AS.req_num = zipf.distr .* (total_requests / length(ASes_with_users) );
	requests_at_each_AS.req_num = round(requests_at_each_AS.req_num);
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


	RatePerQuality = represent_in_opl( "RatePerQuality", rate_per_quality, true, "array" );

	CachePerQuality = represent_in_opl( "CachePerQuality", cache_per_quality, true, "array" );

	utility_per_quality = [0, 1, utility_ratio];
	UtilityPerQuality = represent_in_opl(
							"UtilityPerQuality", utility_per_quality, true, "array" );


	% Each object is published by only one producer
	objects_producer_mapping_per_objects = zeros(1,length(ases) );
	objects_producer_mapping_per_objects(1, server) = 1;
	objects_published_by_producers = repmat(objects_producer_mapping_per_objects, catalog_size, 1);
	ObjectsPublishedByProducers = represent_in_opl( 
				"ObjectsPublishedByProducers", objects_published_by_producers, false, "array" );


	MaxCacheStorageAtSingleAS = sprintf(
					"MaxCacheStorageAtSingleAS = %g", max_storage_at_single_as);

	MaxCacheStorage = sprintf( "MaxCacheStorageAtSingleAS = %g", max_cache_storage);

	f = fopen(filename, "w");
	fprintf(f, "%s\n",ASes);
	fprintf(f, "%s\n",Objects);
	fprintf(f, "%s\n",QualityLevels);
	fprintf(f, "%s\n",Arcs);
	fprintf(f, "%s\n",ObjRequests);
	fprintf(f, "%s\n",RatePerQuality);
	fprintf(f, "%s\n",UtilityPerQuality);
	fprintf(f, "%s\n",ObjectsPublishedByProducers);
	fprintf(f, "%s\n",MaxCacheStorageAtSingleAS);
	fprintf(f, "%s\n",MaxCacheStorage);
	fclose(f);
	
endfunction
