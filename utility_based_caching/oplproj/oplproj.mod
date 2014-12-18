/*********************************************
 * OPL 12.5 Model
 * Author: araldo_local
 * Creation Date: Dec 18, 2014 at 1:37:10 PM
 *********************************************/
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
int O_BF_card   = ...;
int O_OF_card   = ...;
int O_LQ_card   = ...;
int O_HQ_card   = ...;

/*********************************************************
* Range variables
*********************************************************/
setof(int) Q = ...;

range ASes      = 1..NumASes;
range O_BF   = 1..O_BF_card;
range O_OF   = O_BF_card+1 .. O_BF_card+O_OF_card;
range O_LQ   = O_BF_card+O_LQ_card+1 .. O_BF_card+ O_LQ_card+ O_LQ_card ;
range O_HQ   = O_BF_card+ O_LQ_card+ O_LQ_card+1 .. O_BF_card+ O_LQ_card+ O_LQ_card+O_HQ_card ;
range O_F	 = 1..O_BF_card+O_OF_card;
range O = 1 .. O_BF_card+ O_LQ_card+ O_LQ_card+O_HQ_card;


/*********************************************************
* Input Parameters
*********************************************************/
int a[O][ASes]							=...;
int s[Q]								=...;	
float b[ASes][ASes]								=...;
float K											=...;
float M											=...;
float hmin[Q]							=...;
float hmax[Q]							=...;
float S									=...;

int   ObjectReachabilityMatrix[ASes][O]				= ...;
float d[O][ASes]							= ...;
float TransitPrice[ASes]									= ...;
float CachePrice                                         = ...;
float MaxCachePerBorderRouter                            = ...;
float MaxCoreCache 							 = ...;
float MaxTotalCache                                      = ...;


/*********************************************************
* Intermediate variables
*********************************************************/
float TotalDemandInverse;
execute
{
		var TotalDemand = 0;
		for (var o in O)
		{		
			for (var a_ in ASes)
				TotalDemand += d[o][a_];
		}
		TotalDemandInverse = 1/TotalDemand;
};


/*********************************************************
* Decision variables
*********************************************************/
dvar boolean x[O][ASes][Q];
dvar boolean I[O][ASes][Q];
dvar float+  y[O][ASes][ASes][ASes];
dvar float+  y_to_u[O][ASes][Q];
dvar float+  y_from_source[O][ASes][Q];
dvar float+  r[O][ASes];


dvar float+  BorderRouterCacheStorage[ASes];
dvar float+  CoreRouterCacheStorage;
dvar boolean BorderRouterCachedObjectsFlag[ASes][O];
dvar boolean CoreRouterCachedObjectsFlag[O];
dvar float+  CacheTrafficFlow[ASes][O];
dvar float+  TransitTrafficFlow[ASes][O];

/*********************************************************
* ILP MODEL: Objective Function
*********************************************************/

//<aa>
dexpr float HitRatio = 
	1 - sum ( i in ASes, o in O )
		(	TransitTrafficFlow[i][o] * TotalDemandInverse
		);

maximize HitRatio;
//</aa>

/*********************************************************
* ILP MODEL: Constraints
*********************************************************/

subject to {
	forall( o in O, i in ASes, q in Q)
	ct2:
		x[o][i][q] >= a[o][i];


	forall( o in O, a_ in ASes)
	ct3:
		sum( q in Q ) I[o][a_][q] == 1;


	forall( o in O_F, q in Q diff {1}, i in ASes, a_ in ASes )
	ct4:
		x[o][i][q] == I[o][a_][q] == 0;
		
	forall( o in O_LQ, q in Q diff {2}, i in ASes, a_ in ASes )
	ct5:
		x[o][i][q] == I[o][a_][q] == 0;

		
	forall( o in O_HQ,  i in ASes, a_ in ASes )
	ct6:
		x[o][i][1] == I[o][a_][1] == 0;


	ct7:
		sum(i in ASes) sum( o in O ) sum(q in Q) (x[o][i][q] - a[o][i] ) * s[q] <= S;


	ct8:
		sum( o in O ) (CoreRouterCachedObjectsFlag[o]) <= CoreRouterCacheStorage;
	
}

execute DISPLAY {
	writeln("Optimization results\n\n");
	
	var i;
	var o;

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

   	for (i in ASes)
	{
    	for (o in O) {
    			f_border_router_cached_objects_in_scenarios.writeln(  ";" + i + ";" + o + ";" + BorderRouterCachedObjectsFlag[i][o]);
    			f_transit_traffic_in_scenarios.writeln(  ";" + i + ";" + o + ";" + TransitTrafficFlow[i][o]);
    			f_intra_as_traffic_in_scenarios.writeln(  ";" + i + ";" + o + ";" + CacheTrafficFlow[i][o]);
		}
	}
	
	for (o in O)
		f_core_router_cached_objects_in_scenarios.writeln(o + ";" + CoreRouterCachedObjectsFlag[o]);


	//<aa> Compute and print the TotalCost
	var BorderRouterStorage = 0;
	for (i in ASes)
		BorderRouterStorage += BorderRouterCacheStorage[i];

	var TotalCost = 0;


	var TotalCost = 0;
	for (o in O)
		for (i in ASes)
			TotalCost += TransitPrice[i] * TransitTrafficFlow[i][o];
	TotalCost += CachePrice * BorderRouterStorage + 
						CachePrice * CoreRouterCacheStorage;



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

	for (var a_ in ASes)
   	for (o in O) {
    		var check = 0;

    		check += d[o][a_] * CoreRouterCachedObjectsFlag[o];

    		for (i in ASes)
    			check += CacheTrafficFlow[i][o];

    		if (check != d[o] [a_]) {
    			writeln("ERROR! Demand not satisfied: Expected " + d[o][a_] + ", Actual Value " + check);
    		}

   	}

	// Transit flow should be zero if object is cached in border router

	for (o in O)
		for (i in ASes)
			if (TransitTrafficFlow[i][o] > 0 && BorderRouterCachedObjectsFlag[i][o] == 1) {
				writeln("ERROR! Even though border router is caching object, there is some outgoing traffic");
			}

	// Cache flow should be zero if object is cached in core router

	for (o in O)
		for (i in ASes)
			if (CacheTrafficFlow[i][o] > 0 && CoreRouterCachedObjectsFlag[o] == 1) {
				writeln("ERROR! Even though core router is caching object, there is some outgoing traffic");
			}
}