
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
float MaxCacheStorageAtSingleAS = ...;
float MaxCacheStorage = ...;


float MaxEgressCapacityAtAS[ASes];

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
}

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
	sum( r in ObjRequests, q in QualityLevels ) ( ObjectRequestsServed[r][q] * UtilityPerQuality[q] ) / 
	sum( r in ObjRequests) (r.numOfObjectRequests);

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
	  	sum ( o in Objects, q in QualityLevels ) ( ObjectCached[o][q][sourceAS] * CacheSpacePerQuality[q] ) <= MaxCacheStorageAtSingleAS;
	
	ctTotalCacheSize:
	  	sum ( o in Objects, q in QualityLevels, sourceAS in ASes ) ( ObjectCached[o][q][sourceAS] * CacheSpacePerQuality[q] ) <= MaxCacheStorage;

}





/*********************************************************
* PRINT RESULTS
*********************************************************/
execute DISPLAY 
{
  	/************************************
  	 *** Print cached quality levels *****
  	 ************************************/
	var f = new IloOplOutputFile("quality_cached.csv");
	f.open;
	f.write("AS\t");
	for (var q in QualityLevels)
		if (q>0) f.write("#q=",q, "\t");
	f.write("\n");
	for (var as in ASes)
	{
		f.write(as, "\t");
		for (var q in QualityLevels)
		{
		  	if (q>0){
				var num_cached  = 0;
				for (var o in Objects) num_cached += ObjectCached[o][q][as];
				f.write(num_cached,"\t");		
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
	f.write("rank\t");
	for (var as in ASes) f.write("AS=",as, "\t");
	f.write("\n");
	for (var o in Objects)
	{
		f.write(o, "\t");
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
 			f.write(q_avg, "\t");
		}
		f.write("\n");
	}
	f.close

}


