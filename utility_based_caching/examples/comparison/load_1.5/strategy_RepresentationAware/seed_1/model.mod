
// Versione cooperativa

execute PARAMS {
  // cplex.epgap = 0.05;
  // cplex.tilim = 600;
}

tuple Arc {
	key int sourceAS;
	key int targetAS;
	float linkCapacity;
}

/**
* Utilizzare questa formulazione rende il .mod più compatto e
* ne velocizza l'esecuzione (quando un sottoinsieme degli AS 
* si comporta come consumer o richiede solamente un sottoinsieme
* degli oggetti)
**/

tuple ObjRequest {
	key int object;
	key int sourceAS;
	int numOfObjectRequests;
}	

/*********************************************************
* Basic Sets
*********************************************************/

{int} ASes = ...;
{int} Objects = ...;
{int} QualityLevels = ...;

/*********************************************************
* Input Parameters
*********************************************************/

{Arc} Arcs with sourceAS in ASes, targetAS in ASes = ...;
{ObjRequest} ObjRequests with object in Objects, sourceAS in ASes = ...;

float RatePerQuality[QualityLevels] = ...;
float CacheSpacePerQuality[QualityLevels] = ...;
float UtilityPerQuality[QualityLevels] = ...;
int   ObjectsPublishedByProducers[Objects][ASes] = ...;
float MaxCacheStorageAtSingleAS[ASes] = ...;
float MaxCacheStorage = ...;

//<aa>
// 0 for Representation Aware
// 1 for No Cache
// 2 for Always Low Quality, 
// 3 for Always High Quality
// 4 for All Quality Levels
// 5 for Dedicated Cache
int Strategy = ...;
//</aa>


float MaxEgressCapacityAtAS[ASes];

//<aa>
int MaxQualityLevel;
//</aa>

execute {
  for (var as in ASes)
  	MaxEgressCapacityAtAS[as] = 0;
  
  for (var arc in Arcs)
  	MaxEgressCapacityAtAS[arc.sourceAS] += arc.linkCapacity;
  	
  for (var as in ASes) {
    var maxCapacity = 0;
    var maxRate = 0;
    
    for (var q in QualityLevels)
    	if (maxRate < RatePerQuality[q])
    		maxRate = RatePerQuality[q];
    		
    for (var r in ObjRequests)
    	if (r.sourceAS == as)
    		maxCapacity += maxRate * r.numOfObjectRequests; 
    
    if (maxCapacity > MaxEgressCapacityAtAS[as])
    	MaxEgressCapacityAtAS[as] = maxCapacity;
  }

  //<aa>
	// Find the maximum quality level
	MaxQualityLevel=0;
	for (var q in QualityLevels)
	{
		if (q> MaxQualityLevel)
			MaxQualityLevel = q;
	}
  //</aa> 	  
}

//<aa>
/*********************************************************
* Input checks
*********************************************************/
int error = 0;

execute INPUT_CHECKS{
	for (q in QualityLevels)
		if (q != 0 && q!=1 && q!=2 && q!=3 && q!=4 && q!=5)
		{
			writeln ("ERROR: Only quality levels 0:5 are admissible");
			exit;
		}
}
//<aa>


/*********************************************************
* Decision variables
*********************************************************/

dvar int+    ObjectRequestsServed[ObjRequests][QualityLevels];
dvar boolean ObjectCached[Objects][QualityLevels][ASes];
dvar float+  Flow[ObjRequests][QualityLevels][Arcs];
dvar float+  TrafficDemand[ObjRequests][QualityLevels];
dvar float+  FlowServedByProducers[ObjRequests][QualityLevels][ASes];
dvar float+  FlowServedByCache[ObjRequests][QualityLevels][ASes];

/*********************************************************
* ILP MODEL: Objective Function
*********************************************************/

maximize 
	sum( r in ObjRequests, q in QualityLevels ) ( ObjectRequestsServed[r][q] * UtilityPerQuality[q] ) ;

subject to {

	forall ( r in ObjRequests )
	ctRequestsServed:
		sum ( q in QualityLevels ) ( ObjectRequestsServed[r][q] ) == r.numOfObjectRequests;
	
	forall ( r in ObjRequests, q in QualityLevels )
	ctTrafficDemand:
		TrafficDemand[r][q] == ObjectRequestsServed[r][q] * RatePerQuality[q];
		
	forall ( r in ObjRequests, q in QualityLevels )
	ctDemandServed:
	  	TrafficDemand[r][q] == 
	  		FlowServedByProducers[r][q][r.sourceAS] + 
	  		FlowServedByCache[r][q][r.sourceAS] +
	  		sum ( a in Arcs : a.targetAS == r.sourceAS ) ( Flow[r][q][a] ) -
  			sum ( a in Arcs : a.sourceAS == r.sourceAS ) ( Flow[r][q][a] );
			
	forall ( r in ObjRequests, q in QualityLevels, sourceAS in ASes : sourceAS != r.sourceAS )
	ctFlowBalanceCooperative:
	  	FlowServedByProducers[r][q][sourceAS] +
	  	FlowServedByCache[r][q][sourceAS] +
	  	sum ( a in Arcs : a.targetAS == sourceAS ) ( Flow[r][q][a] ) -
  		sum ( a in Arcs : a.sourceAS == sourceAS ) ( Flow[r][q][a] ) == 0;
		
	forall ( a in Arcs )
	ctCapacityConstraint:
		sum ( r in ObjRequests, q in QualityLevels ) ( Flow[r][q][a] ) <= a.linkCapacity;
		
	forall ( o in Objects, q in QualityLevels, sourceAS in ASes )
	ctProducerCapacityConstraint:
		sum ( r in ObjRequests : r.object == o ) ( FlowServedByProducers[r][q][sourceAS] ) <= ObjectsPublishedByProducers[o][sourceAS] * MaxEgressCapacityAtAS[sourceAS];
		
	forall ( o in Objects, q in QualityLevels, sourceAS in ASes )
	ctCacheCapacityConstraint:
		sum ( r in ObjRequests : r.object == o ) ( FlowServedByCache[r][q][sourceAS] ) <= ObjectCached[o][q][sourceAS] * MaxEgressCapacityAtAS[sourceAS];
		
	forall ( sourceAS in ASes )
	ctLocalCacheSize:
	  	sum ( o in Objects, q in QualityLevels ) ( ObjectCached[o][q][sourceAS] * CacheSpacePerQuality[q] ) <= MaxCacheStorageAtSingleAS[sourceAS];
	
	ctTotalCacheSize:
	  	sum ( o in Objects, q in QualityLevels, sourceAS in ASes ) ( ObjectCached[o][q][sourceAS] * CacheSpacePerQuality[q] ) <= MaxCacheStorage;

	// <aa> Different strategies
	forall (o in Objects, q in QualityLevels, v in ASes)
	cNoCache:
		(Strategy == 1) => ObjectCached[o][q][v] == 0;

	forall (o in Objects, v in ASes, q in QualityLevels : q != 1 )
	cAlwaysLowQuality:
		(Strategy == 2) => ObjectCached[o][q][v] == 0;


	forall (o in Objects, v in ASes, q in QualityLevels : q != MaxQualityLevel )
	cAlwaysHighQuality:
		(Strategy == 3 ) => ObjectCached[o][q][v] == 0;

	forall (o in Objects, v in ASes, q1 in QualityLevels : q1!=0, q2 in QualityLevels: q2!=0)
	cAllQualityLevels:
		(Strategy == 4) => ObjectCached[o][q1][v] == ObjectCached[o][q2][v];


	forall ( sourceAS in ASes, q in QualityLevels )
	cDedicatedCache:
	sum ( o in Objects ) ( ObjectCached[o][q][sourceAS] * CacheSpacePerQuality[q] ) <= MaxCacheStorageAtSingleAS[sourceAS] / ( card(QualityLevels) - 1);
		// I substract -1 from the cardinality of QualityLevels because q=0 is not a real quality level

	// </aa>
}



/*********************************************************
* PRINT RESULTS
*********************************************************/
int RequestsPerQuality[Objects][QualityLevels];




execute DISPLAY 
{
  	/************************************
  	 *** Print objective function
  	 ************************************/
  	var total_utility = 0; var tot_reqs = 0; var avg_utility = 0; 
  	for (var r in ObjRequests) for (q in QualityLevels)
  		total_utility += ObjectRequestsServed[r][q] * UtilityPerQuality[q]; 
	for (var r in ObjRequests) tot_reqs += r.numOfObjectRequests;
	avg_utility = total_utility / tot_reqs;
  	var f = new IloOplOutputFile("objective.csv");
  	f.open;
	f.write("avg_utility\n");
  	f.write(avg_utility,"\n");
  	f.close;

  	var f = new IloOplOutputFile("total_utility.csv");
  	f.open;
	f.write("total_utility\n");
  	f.write(total_utility,"\n");
  	f.close;

  
  	/************************************
  	 *** Print cached quality levels *****
  	 ************************************/
	var f = new IloOplOutputFile("quality_cached.csv");
	f.open;
	f.write("AS ");
	for (var q in QualityLevels)
		if (q>0) f.write("#q=",q, " ");
	f.write("\n");
	for (var as in ASes)
	{
		f.write(as, " ");
		for (var q in QualityLevels)
		{
		  	if (q>0){
				var num_cached  = 0;
				for (var o in Objects) num_cached += ObjectCached[o][q][as];
				f.write(num_cached," ");		
 			}	
		}
		f.write("\n");
	}
	f.close
	
	
	 /************************************
  	 *** Print cached quality levels per rank
  	 ************************************/
	var f = new IloOplOutputFile("quality_cached_per_rank.csv");
	f.open;
	f.write("rank");
	for (var as in ASes) f.write(" AS=",as);
	f.write("\n");
	for (var o in Objects)
	{
		f.write(o);
		for (var as in ASes)
		{
		  	var partial_sum  = 0;
		  	var num_cached_tot = 0;
			for (var q in QualityLevels)
			{ 
				var num_cached_at_q = ObjectCached[o][q][as];
				num_cached_tot += num_cached_at_q;
				partial_sum += q * num_cached_at_q;  
 			}
 			var q_avg = num_cached_tot == 0 ? 
 					0 : partial_sum / num_cached_tot; 
 			f.write(" ",q_avg);
		}
		f.write("\n");
	}
	f.close;


	/************************************
  	 *** Print served quality levels per rank
  	 ************************************/
  	// Initialize the data structure
  	for (var o in Objects) for (var q in QualityLevels)
  		RequestsPerQuality[o][q] = 0;
  		
  	// Populate the data structure
 	for (var r in ObjRequests) for(var q in QualityLevels)
		 RequestsPerQuality[r.object][q] = ObjectRequestsServed[r][q];
	  	
  	// Print to file
	var f = new IloOplOutputFile("quality_served_per_rank.csv");
	f.open;
	f.write("rank q_avg");
	f.write("\n");
	for (var o in Objects)
	{
		f.write(o)
		var partial_sum = 0;
		var q_tot = 0;
		for (var q in QualityLevels){
			partial_sum += RequestsPerQuality[o][q];
			q_tot += q * RequestsPerQuality[o][q];
		}
		var q_avg = q_tot / partial_sum; 
		f.write(" ",q_avg,"\n");
	}	
	
	f.close;

	/************************************
  	 *** Print usatisfied requests
  	 ************************************/
  	 var total_requests = 0;
  	 var satisfied_requests = 0;
  	 for (var r in ObjRequests)
  	 { 
  	 	for(var q in QualityLevels){
			total_requests += ObjectRequestsServed[r][q];
			if (q > 0 )
				satisfied_requests +=  ObjectRequestsServed[r][q];
		}		
	 }
	 var unsatisfied_part = (total_requests - satisfied_requests) / total_requests;  


	var f = new IloOplOutputFile("unsatisfied_ratio.csv");
	f.open;
	f.write("unsatisfied_ratio\n");
	f.write(unsatisfied_part,"\n");
	f.close

	/************************************
  	 *** Print link load
  	 ************************************/
	var f = new IloOplOutputFile("link_load.csv");
	f.open;
	f.write("link load\n");
	for (var a in Arcs)
	{
		var traffic = 0;
		for (var r in ObjRequests)
			for (var q in QualityLevels)
				traffic += Flow[r][q][a];
		var load = traffic / a.linkCapacity;
		f.write(a.sourceAS,"-",a.targetAS," ",load,"\n");
	}
	f.close


	/************************************
  	 *** Print cache sizes
  	 ************************************/
	var f = new IloOplOutputFile("cache_sizes.csv");
	f.open;
	f.write("node size\n");
	for (var a in ASes)
	{
		var size = 0;
		for (var o in Objects)
			for (var q in QualityLevels)
				size += ObjectCached[o][q][a] * CacheSpacePerQuality[q];
		f.write(a," ",size,"\n");
	}
	f.close

}


