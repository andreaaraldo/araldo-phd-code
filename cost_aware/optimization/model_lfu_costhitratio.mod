/* <aa>
 * This model optimize only the cache placement with the goal of minimizing the total cost. 
 * The object placement is the result of the LFU policy.
 * </aa>
 */

/*********************************************************
* Robust Cache provisioning model - LFU cache model
*********************************************************/

execute PARAMS {
  // cplex.epgap = 0.05;
  
  cplex.disjcuts = 3;
  cplex.mcfcuts = 2;
  cplex.implbd = 2;
  cplex.gubcovers = 2;
  cplex.fraccuts = 2;
  cplex.flowpaths = 2;
  cplex.flowcovers = 2;
  cplex.covers = 2;
  cplex.mircuts = 2;
}

/*********************************************************
* Set cardinalities
*********************************************************/

int NumASes      = ...;
int NumObjects   = ...;
int NumScenarios = ...;

/*********************************************************
* Range variables
*********************************************************/

range ASes      = 1..NumASes;
range Objects   = 1..NumObjects;
range Scenarios = 1..NumScenarios;

/*********************************************************
* Input Parameters
*********************************************************/

float RealizationProbabilities[Scenarios]                = ...;
int   ObjectReachabilityMatrix[ASes][Objects][Scenarios] = ...;
int TrafficDemand[Objects][Scenarios]                  = ...;
float TransitPrice[ASes][Scenarios]                      = ...;
float CachePrice                                         = ...;
float MaxCachePerBorderRouter                            = ...;
float MaxCoreCache 							 = ...;
float MaxTotalCache                                      = ...;


//<aa>
/*********************************************************
* Intermediate variables
*********************************************************/
float TotalDemandInverse[Scenarios];
execute
{
	for( s in Scenarios )
	{
		var TotalDemand = 0;
		for (o in Objects)
			TotalDemand += TrafficDemand[o][s];
		TotalDemandInverse[s] = 1/TotalDemand;
	}
};
//</aa>


/*********************************************************
* Compute demand ordering at the core router
*********************************************************/

int IsDemandLower[Objects][Objects][Scenarios];

execute
{
  var o1;
  var o2;
  var s;
  
  for( o1 in Objects )
  	for ( o2 in Objects )
  		for ( s in Scenarios )
  			if ( TrafficDemand[o1][s] < TrafficDemand[o2][s] )
    			IsDemandLower[o1][o2][s] = 1;
    		else
    			IsDemandLower[o1][o2][s] = 0;
};
	
	
		
/*********************************************************
* Compute the maximum delta demand
*********************************************************/

int B = max( o in Objects, s in Scenarios )(TrafficDemand[o][s]) + 1;

/*********************************************************
* Decision variables
*********************************************************/

dvar int+  BorderRouterCacheStorage[ASes];
dvar int+  CoreRouterCacheStorage;
dvar boolean BorderRouterCachedObjectsFlag[ASes][Objects][Scenarios];
dvar boolean CoreRouterCachedObjectsFlag[Objects][Scenarios];
dvar int+  CacheTrafficFlow[ASes][Objects][Scenarios];
dvar int+  TransitTrafficFlow[ASes][Objects][Scenarios];
dvar boolean IsTrafficLowerAtBorderRouter[Objects][Objects][Scenarios][ASes];

/*********************************************************
* ILP MODEL: Objective Function
*********************************************************/

dexpr float TotalCost = 
	sum ( s in Scenarios )
		RealizationProbabilities[s] * (
			sum ( o in Objects, i in ASes ) 
				TransitPrice[i][s] * TransitTrafficFlow[i][o][s]
		)
	+
	CachePrice * 
		sum( i in ASes )
			BorderRouterCacheStorage[i]
	+
	CachePrice * CoreRouterCacheStorage;

dexpr float HitRatio = 
	1 - sum ( s in Scenarios )
		RealizationProbabilities[s] * 
		(
			sum ( i in ASes, o in Objects )
				(	TransitTrafficFlow[i][o][s] *
					TotalDemandInverse[s]
				)
		);


minimize TotalCost + 0.5 * HitRatio;

/*********************************************************
* ILP MODEL: Constraints
*********************************************************/

subject to {
	forall( i in ASes, o in Objects, s in Scenarios )
	ct1:
		CacheTrafficFlow[i][o][s] <= TransitTrafficFlow[i][o][s] + TrafficDemand[o][s] * BorderRouterCachedObjectsFlag[i][o][s];

	forall( i in ASes, o in Objects, s in Scenarios )
	ct2:
		(CacheTrafficFlow[i][o][s] + TransitTrafficFlow[i][o][s]) * (1 - ObjectReachabilityMatrix[i][o][s]) <= 0;

	forall( o in Objects, s in Scenarios )
	ct3:
		TrafficDemand[o][s] == CoreRouterCachedObjectsFlag[o][s] * TrafficDemand[o][s] + sum ( i in ASes ) (CacheTrafficFlow[i][o][s]);

	forall( i in ASes )
	ct4:
		BorderRouterCacheStorage[i] <= MaxCachePerBorderRouter;

	ct5:
		CoreRouterCacheStorage <= MaxCoreCache;

	ct6:
		CoreRouterCacheStorage + sum( i in ASes ) (BorderRouterCacheStorage[i]) <= MaxTotalCache;

	forall( i in ASes, s in Scenarios )
	ct7:
		sum( o in Objects ) (BorderRouterCachedObjectsFlag[i][o][s]) <= BorderRouterCacheStorage[i];

	forall( s in Scenarios )
	ct8:
		sum( o in Objects ) (CoreRouterCachedObjectsFlag[o][s]) <= CoreRouterCacheStorage;
		
	forall( o1 in Objects, o2 in Objects, s in Scenarios )
	ct9:
		CoreRouterCachedObjectsFlag[o2][s] >= CoreRouterCachedObjectsFlag[o1][s] * IsDemandLower[o1][o2][s];
	
	forall( o1 in Objects, o2 in Objects, i in ASes, s in Scenarios ) 
	ct10:
		-BorderRouterCachedObjectsFlag[i][o1][s] + BorderRouterCachedObjectsFlag[i][o2][s] - IsTrafficLowerAtBorderRouter[o1][o2][s][i] + 1 >= 0;
		
	forall( o1 in Objects, o2 in Objects, i in ASes, s in Scenarios ) 
	ct11:
		CacheTrafficFlow[i][o2][s] - CacheTrafficFlow[i][o1][s] <= B * IsTrafficLowerAtBorderRouter[o1][o2][s][i];
}

execute DISPLAY {
	writeln("Optimization results\n\n");
	
	var i;
	var o;
	var o1;
	var o2;
	var s;

	var f_obj_function = new IloOplOutputFile("obj_function.csv");
	f_obj_function.open;
	f_obj_function.write(TotalCost);
	f_obj_function.close;

    var f_border_router_cache_sizes = new IloOplOutputFile("border_router_cache_sizes.csv");
    f_border_router_cache_sizes.open;

    for (i in ASes)
    	if (i > 1)
    		f_border_router_cache_sizes.write(";" + BorderRouterCacheStorage[i]);
		else
    		f_border_router_cache_sizes.write(BorderRouterCacheStorage[i]);

    f_border_router_cache_sizes.close;

    var f_core_router_cache_size = new IloOplOutputFile("core_router_cache_size.csv");
    f_core_router_cache_size.open;
	f_core_router_cache_size.write(CoreRouterCacheStorage);
    f_core_router_cache_size.close;

    var f_border_router_cached_objects_in_scenarios = new IloOplOutputFile("cached_objects_border_router_scenarios.csv");
    var f_core_router_cached_objects_in_scenarios = new IloOplOutputFile("cached_objects_core_router_scenaris.csv");
    var f_transit_traffic_in_scenarios = new IloOplOutputFile("transit_traffic.csv");
    var f_intra_as_traffic_in_scenarios = new IloOplOutputFile("intra_as_traffic.csv");
	//<aa>
	var f_hitratio = new IloOplOutputFile("hitratio.csv"); 
	var f_totalcost = new IloOplOutputFile("totalcost.csv"); 
	//</aa>

    f_border_router_cached_objects_in_scenarios.open;
    f_core_router_cached_objects_in_scenarios.open;
    f_transit_traffic_in_scenarios.open;
    f_intra_as_traffic_in_scenarios.open;
	//<aa>
	f_hitratio.open;
	f_totalcost.open;
	//</aa>


    for (s in Scenarios)
	{    
		for (i in ASes)
    		for (o in Objects) {
    			f_border_router_cached_objects_in_scenarios.writeln(s + ";" + i + ";" + o + ";" + BorderRouterCachedObjectsFlag[i][o][s]);
    			f_transit_traffic_in_scenarios.writeln(s + ";" + i + ";" + o + ";" + TransitTrafficFlow[i][o][s]);
    			f_intra_as_traffic_in_scenarios.writeln(s + ";" + i + ";" + o + ";" + CacheTrafficFlow[i][o][s]);
			}
	}

	for (s in Scenarios)
		for (o in Objects)
			f_core_router_cached_objects_in_scenarios.writeln(s + ";" + o + ";" + CoreRouterCachedObjectsFlag[o][s]);

	//<aa>
	var hitratio = 0;

	for (s in Scenarios)
	{
		// Compute total_transit_traffic
		var total_transit_traffic = 0;
		for (o in Objects)
			for (i in ASes)
				total_transit_traffic += TransitTrafficFlow[i][o][s];

		// Compute total demand
		var total_demand = 0;
		for (o in Objects)
			total_demand += TrafficDemand[o][s];

		hitratio += RealizationProbabilities[s] * (1 - total_transit_traffic / total_demand);
	}

	f_hitratio.writeln(hitratio );
	f_totalcost.writeln(TotalCost );
	//</aa>


    f_border_router_cached_objects_in_scenarios.close;
    f_core_router_cached_objects_in_scenarios.close;
    f_transit_traffic_in_scenarios.close;
    f_intra_as_traffic_in_scenarios.close;
	//<aa>
	f_hitratio.close;
	f_totalcost.close;
	//</aa>

    ////////////////////////////////////
    // TESTS
    ////////////////////////////////////

    // Demand should be satisfied

    for (s in Scenarios)
    	for (o in Objects) {
    		var check = 0;

    		check += TrafficDemand[o][s] * CoreRouterCachedObjectsFlag[o][s];

    		for (i in ASes)
    			check += CacheTrafficFlow[i][o][s];

    		if (check != TrafficDemand[o][s]) {
    			writeln("ERROR! Demand not satisfied: Expected " + TrafficDemand[o][s] + ", Actual Value " + check);
    		}

    	}

	// Transit flow should be zero if object is cached in border router

	for (s in Scenarios)
		for (o in Objects)
			for (i in ASes)
				if (TransitTrafficFlow[i][o][s] > 0 && BorderRouterCachedObjectsFlag[i][o][s] == 1) {
					writeln("ERROR! Even though border router is caching object, there is some outgoing traffic");
				}

	// Cache flow should be zero if object is cached in core router

	for (s in Scenarios)
		for (o in Objects)
			for (i in ASes)
				if (CacheTrafficFlow[i][o][s] > 0 && CoreRouterCachedObjectsFlag[o][s] == 1) {
					writeln("ERROR! Even though core router is caching object, there is some outgoing traffic");
				}
				
	// Check whether the core router cache is behaving as an LFU cache
	
	for (s in Scenarios)
		for (o1 in Objects)
			if (CoreRouterCachedObjectsFlag[o1][s] == 0)
				for (o2 in Objects)
					if (TrafficDemand[o2][s] < TrafficDemand[o1][s] && CoreRouterCachedObjectsFlag[o2][s] == 1)
						writeln("ERROR! The core router is not behaving like a LFU cache");

	// Check whether the border router caches are behaving as LFU caches
	
	for (s in Scenarios)
		for (i in ASes)
			for (o1 in Objects)
				if (BorderRouterCachedObjectsFlag[i][o1][s] == 0)
					for (o2 in Objects)
						if (CacheTrafficFlow[i][o2][s] < CacheTrafficFlow[i][o1][s] && BorderRouterCachedObjectsFlag[i][o2][s] == 1)
							writeln("ERROR! The border router is not behaving like a LFU cache");
}
