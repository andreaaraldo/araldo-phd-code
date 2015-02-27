/* <aa>
 * This model jointly optimizes cache placement and object placement with the goal of minimizing the total cost
 * </aa>
 */


/*********************************************************
* Robust Cache provisioning model
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
float TrafficDemand[Objects][Scenarios]                  = ...;
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
* Decision variables
*********************************************************/

dvar float+  BorderRouterCacheStorage[ASes];
dvar float+  CoreRouterCacheStorage;
dvar boolean BorderRouterCachedObjectsFlag[ASes][Objects][Scenarios];
dvar boolean CoreRouterCachedObjectsFlag[Objects][Scenarios];
dvar float+  CacheTrafficFlow[ASes][Objects][Scenarios];
dvar float+  TransitTrafficFlow[ASes][Objects][Scenarios];

/*********************************************************
* ILP MODEL: Objective Function
*********************************************************/

//<aa>
dexpr float HitRatio = 
	1 - sum ( s in Scenarios )
		RealizationProbabilities[s] * 
		(
			sum ( i in ASes, o in Objects )
				(	TransitTrafficFlow[i][o][s] *
					TotalDemandInverse[s]
				)
		);

maximize HitRatio;
//</aa>

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
	
}

execute DISPLAY {
	writeln("Optimization results\n\n");
	
	var i;
	var o;
	var s;

	var f_obj_function = new IloOplOutputFile("obj_function.csv");
	f_obj_function.open;
	f_obj_function.write(HitRatio); //<aa>Stampo HitRatio e non costo</aa>
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


	//<aa> Compute and print the TotalCost
	var BorderRouterStorage = 0;
	for (i in ASes)
		BorderRouterStorage += BorderRouterCacheStorage[i];

	var TotalCost = 0;

	for (s in Scenarios)
	{
		var TotalCost_in_scenario = 0;
		for (o in Objects)
			for (i in ASes)
				TotalCost_in_scenario += TransitPrice[i][s] * TransitTrafficFlow[i][o][s];

		TotalCost_in_scenario += CachePrice * BorderRouterStorage + 
								CachePrice * CoreRouterCacheStorage;
	
		TotalCost += RealizationProbabilities[s] * TotalCost_in_scenario;
	}
	f_totalcost.writeln(TotalCost );
	//</aa>

	//<aa>
	f_hitratio.writeln(HitRatio );
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
}
