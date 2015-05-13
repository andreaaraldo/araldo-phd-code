% Called by scenario_script.m
function generate_opl_dat(singledata)

	rand("state",singledata.seed);
	
	objects = 1:singledata.catalog_size;
	quality_level_num = length(singledata.fixed_data.rate_per_quality)-1; % number of qualities starting from q=1
	quality_levels = 0:quality_level_num;

	ASes = represent_in_opl( "ASes", singledata.topology.ases, true, "set" );
	Objects = represent_in_opl( "Objects", objects, true, "set" );
	QualityLevels = represent_in_opl( "QualityLevels", quality_levels, true, "set" );
	Arcs = sprintf("Arcs = %s\n", singledata.topology.arcs);



	%{ RETRIEVE_OBJ_REQUESTS
	ObjRequests = "";
		if ( !exist(singledata.request_file) )
			error(sprintf("File %s does not exist", singledata.request_file) );
		else
			f = fopen(singledata.request_file, "r");
			ObjRequests = fgetl(f);
			fclose(f);
		endif % request_file existence

		if length(ObjRequests) == 0
			error("ObjectRequests malformed");
		endif
	%} RETRIEVE_OBJ_REQUESTS


	RatePerQuality = represent_in_opl( "RatePerQuality", singledata.fixed_data.rate_per_quality, true, "array" );

	% {BUILD CACHE_SPACE_PER_QUALITY
	cache_space_per_quality = [10000];
	for idx_q = 2:quality_level_num+1
		cache_space_per_quality = [cache_space_per_quality, ...
			singledata.fixed_data.cache_space_at_low_quality * ...
			singledata.fixed_data.rate_per_quality(idx_q) / ...
			singledata.fixed_data.rate_per_quality(2) ];
	end % for

	CacheSpacePerQuality = represent_in_opl( "CacheSpacePerQuality", 
				cache_space_per_quality, true, "array" );
	% }BUILD CACHE_SPACE_PER_QUALITY

	UtilityPerQuality = represent_in_opl("UtilityPerQuality", 
				singledata.fixed_data.utilities, true, "array" );

	% BUILD MAX_STORAGE_AT_SINGLE_AS{
		cache_space_at_high_q = max(cache_space_per_quality(2:length(cache_space_per_quality) ) );
		max_cache_storage = (singledata.catalog_size * singledata.cache_to_ctlg_ratio) ...
							* cache_space_at_high_q ; % IN MB
		single_cache_storage = [];
		switch(singledata.cache_allocation)
			case "free"
				single_cache_storage = max_cache_storage;

			case "constrained"
				single_cache_storage = max_cache_storage / length(singledata.topology.ases_with_storage);

			otherwise
				error(sprintf("%s is not a valid cache allocation", singledata.cache_allocation) );
		end%switch 

		max_storage_at_single_as = -1 .* ones(1,max(singledata.topology.ases) );
		for as_ = singledata.topology.ases
			if (any(singledata.topology.ases_with_storage == as_) )
				max_storage_at_single_as(as_) = single_cache_storage;
			else
				max_storage_at_single_as(as_) = 0;
			end %if
		end %for idx_as

		MaxCacheStorageAtSingleAS = represent_in_opl(
			"MaxCacheStorageAtSingleAS", max_storage_at_single_as, true, "array");
	% }BUILD MAX_STORAGE_AT_SINGLE_AS


	%{OBJECT MAPPING
	% Each object is published by only one producer
	obj_srv_assignement = randint(singledata.catalog_size, 1, [1,length(singledata.topology.servers )]);
	objects_published_by_producers = zeros(singledata.catalog_size,length(singledata.topology.ases) );
	for server_idx = 1:length(singledata.topology.servers)
		objects_assigned_to_srv = find(obj_srv_assignement == server_idx);
		server_id = singledata.topology.servers(server_idx);
		objects_published_by_producers(objects_assigned_to_srv, server_id ) = 1;
	end %for
	ObjectsPublishedByProducers = represent_in_opl( 
				"ObjectsPublishedByProducers", objects_published_by_producers, false, "array" );
	%}OBJECT MAPPING

	cache_space_at_high_q = max(cache_space_per_quality(2:length(cache_space_per_quality) ) );
	max_cache_storage = (singledata.catalog_size * singledata.cache_to_ctlg_ratio) ...
					* cache_space_at_high_q ; % IN MB

	MaxCacheStorage = sprintf( "MaxCacheStorage = %g ;", max_cache_storage);
	TimeLimit = sprintf( "TimeLimit = %g ;", singledata.timelimit);
	SolutionGap = sprintf( "SolutionGap = %g ;", singledata.solutiongap);

	f = fopen(singledata.dat_filename, "w");
	if (f==-1)
		error(sprintf("Error in writing file %s",dat_filename) );
	endif

	fprintf(f, "%s\n",ASes);
	fprintf(f, "%s\n",Objects);
	fprintf(f, "%s\n",QualityLevels);
	fprintf(f, "%s\n",Arcs);
	fprintf(f, "%s\n",RatePerQuality);
	fprintf(f, "%s\n",CacheSpacePerQuality);
	fprintf(f, "%s\n",UtilityPerQuality);
	fprintf(f, "%s\n",ObjectsPublishedByProducers);
	fprintf(f, "%s\n",ObjRequests);
	fprintf(f, "%s\n",MaxCacheStorageAtSingleAS);
	fprintf(f, "%s\n",MaxCacheStorage);
	fprintf(f, "%s\n",TimeLimit);
	fprintf(f, "%s\n",SolutionGap);
	fclose(f);

	printf("File %s written\n", singledata.dat_filename);
	
endfunction
