% Called by scenario_script.m
function generate_opl_dat(ases, quality_levels, catalog_size, alpha,
			rate_per_quality, 
			cache_space_per_quality, utilities,
			ASes_with_users, server, total_requests,
			arcs, max_storage_at_single_as, max_cache_storage, seed, dat_filename,
			strategy_)

	objects = 1:catalog_size;

	ASes = represent_in_opl( "ASes", ases, true, "set" );
	Objects = represent_in_opl( "Objects", objects, true, "set" );
	QualityLevels = represent_in_opl( "QualityLevels", quality_levels, true, "set" );
	Arcs = sprintf("Arcs = %s\n", arcs);



	############ Generate ObjRequests ##################
	number_of_object_classes = catalog_size;
	num_of_req_at_each_as = round(total_requests / length(ASes_with_users) );
	[requests_for_each_class, requests_for_each_object] = ZipfQuantizedRng(
					catalog_size, number_of_object_classes, num_of_req_at_each_as, alpha);

	requests_at_each_AS.obj = 1:catalog_size;
	requests_at_each_AS.req_num = requests_for_each_object;
	requests.ASes = ASes_with_users;
	ObjRequests = sprintf("ObjRequests = { ");
	for i = 1:length(ASes_with_users)
		as = ASes_with_users(i);
		for j = 1:catalog_size
			obj = requests_at_each_AS.obj(j);
			req_num = requests_at_each_AS.req_num(j);
			ObjRequests = sprintf("%s <%g,%g,%g>,",ObjRequests, obj, as, req_num);
		endfor
	endfor
	ObjRequests = sprintf("%s};",ObjRequests);
	ObjRequests(length(ObjRequests)-2) = " ";


	% GENERATE_STRATEGY{
	strategy_num = 0;
	switch (strategy_)
		 case "RepresentationAware"
			strategy_num = 0;
		 case "NoCache"
			strategy_num = 1;
		 case "AlwaysLowQuality"
			strategy_num = 2;
		 case "AlwaysHighQuality"
			strategy_num = 3;
		 case "AllQualityLevels"
			strategy_num = 4;
		 case "DedicatedCache"
			strategy_num = 5;
		otherwise
			error("Invalid strategy_");	
	end %swictch
	Strategy = sprintf("Strategy = %d ;", strategy_num);
	% }GENERATE_STRATEGY


	RatePerQuality = represent_in_opl( "RatePerQuality", rate_per_quality, true, "array" );

	CacheSpacePerQuality = represent_in_opl( "CacheSpacePerQuality", cache_space_per_quality, true, "array" );

	utility_per_quality = utilities;
	UtilityPerQuality = represent_in_opl(
							"UtilityPerQuality", utility_per_quality, true, "array" );

	MaxCacheStorageAtSingleAS = represent_in_opl(
					"MaxCacheStorageAtSingleAS", max_storage_at_single_as, true, "array");

	


	% Each object is published by only one producer
	objects_producer_mapping_per_objects = zeros(1,length(ases) );
	objects_producer_mapping_per_objects(1, server) = 1;
	objects_published_by_producers = repmat(objects_producer_mapping_per_objects, catalog_size, 1);
	ObjectsPublishedByProducers = represent_in_opl( 
				"ObjectsPublishedByProducers", objects_published_by_producers, false, "array" );



	MaxCacheStorage = sprintf( "MaxCacheStorage = %g ;", max_cache_storage);

	f = fopen(dat_filename, "w");
	if (f==-1)
		error(sprintf("Error in writing file %s",dat_filename) );
	endif
	fprintf(f, "%s\n",ASes);
	fprintf(f, "%s\n",Objects);
	fprintf(f, "%s\n",QualityLevels);
	fprintf(f, "%s\n",Arcs);
	fprintf(f, "%s\n",ObjRequests);
	fprintf(f, "%s\n",RatePerQuality);
	fprintf(f, "%s\n",CacheSpacePerQuality);
	fprintf(f, "%s\n",UtilityPerQuality);
	fprintf(f, "%s\n",ObjectsPublishedByProducers);
	fprintf(f, "%s\n",MaxCacheStorageAtSingleAS);
	fprintf(f, "%s\n",MaxCacheStorage);
	fprintf(f, "%s\n",Strategy);
	fclose(f);

	printf("File %s written\n",dat_filename);
	
endfunction
