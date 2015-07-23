
// Versione cooperativa


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

//########################################################*
// Basic Sets
//########################################################*/

{int} ASes = ...;
{int} Objects = ...;
{int} QualityLevels = ...;

//########################################################*
// Input Parameters
//########################################################*/

{Arc} Arcs with sourceAS in ASes, targetAS in ASes = ...;
{ObjRequest} ObjRequests with object in Objects, sourceAS in ASes = ...;

float RatePerQuality[QualityLevels] = ...;
float CacheSpacePerQuality[QualityLevels] = ...;
float UtilityPerQuality[QualityLevels] = ...;
int   ObjectsPublishedByProducers[Objects][ASes] = ...;
float MaxCacheStorageAtSingleAS[ASes] = ...;
float MaxCacheStorage = ...;
float SolutionGap = ...;



float MaxEgressCapacityAtAS[ASes];

//<aa>
// ################################
// #### COMPUTED QUANTITIES #######
// ################################
// Most of them will be computed after execution and will be useful for
// printing results
int MaxQualityLevel;
int requests_for_each_object[Objects];
int is_requests_for_each_object_computed = 0; // 1 if yes, 0 if not

int RequestsPerQuality[Objects][QualityLevels];
CUSTOMTYPE HowManyRequestsPerQuality[QualityLevels];


// TransmissionsFromCache[a][q] is the number of transmissions at quality q
// arriving at users of AS a.
float transmissions_from_cache[ASes][QualityLevels];

int total_requests = 0;
int is_total_requests_computed = 0; // 1 if yes, 0 if not

float total_utility = 0;
int is_total_utility_computed = 0;

//</aa>


execute
{
  for (var as in ASes)
  	MaxEgressCapacityAtAS[as] = 0;
  
  for (var arc in Arcs)
  	MaxEgressCapacityAtAS[arc.sourceAS] += arc.linkCapacity;
  	
  for (var as in ASes) 
  {
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
	//{ FIND MAX QUALITY LEVEL
	MaxQualityLevel=0;
	for (var q in QualityLevels)
	{
		if (q> MaxQualityLevel)
			MaxQualityLevel = q;
	}
	//} FIND MAX QUALITY LEVEL


  //</aa> 	  
}

//<aa>
/*
	//########################################################
	// Input checks
	//########################################################/
	execute INPUT_CHECKS
	{
		for (var q in QualityLevels)
			if (q != 0 && q!=1 && q!=2 && q!=3 && q!=4 && q!=5)
			{
				writeln ("ERROR: Only quality levels 0:5 are admissible");
				exit;
			}
	
		for (var o in Objects)
		{
			var sum_ = 0;
			for ( var as_ in ASes )
				sum_ += ObjectsPublishedByProducers[o][as_];
			
			if ( sum_ < 1 )
			{
				writeln ("ERROR: object ", o, " is published by no AS");
				exit;
			}
		}	

	}
*/
//<aa>


execute PARAMS {
  cplex.epgap = SolutionGap;
  //cplex.tilim = 3600;
}


//#######################################################*
// Decision variables
//########################################################*/

dvar CUSTOMTYPE+   ObjectRequestsServed[ObjRequests][QualityLevels];
dvar boolean ObjectCached[Objects][QualityLevels][ASes];
dvar float+  Flow[ObjRequests][QualityLevels][Arcs];
dvar float+  TrafficDemand[ObjRequests][QualityLevels];

// dvar float+  FlowServedByProducers[r][q][as] is the data-rate at which as serves the request r, 
// at quality q, under the role of server
dvar float+  FlowServedByProducers[ObjRequests][QualityLevels][ASes];

dvar float+  FlowServedByCache[ObjRequests][QualityLevels][ASes];

//########################################################*
// ILP MODEL: Objective Function
//########################################################*/

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


	// ####### OTHER STRATEGIES ########
	/*NoCache
	forall (o in Objects, q in QualityLevels, v in ASes)
	cNoCache:
		ObjectCached[o][q][v] == 0;
	NoCache*/

	/*AlwaysLowQuality
	forall (o in Objects, v in ASes, q in QualityLevels : q != 1 )
	cAlwaysLowQuality:
		ObjectCached[o][q][v] == 0;
	AlwaysLowQuality*/

	/*AlwaysHighQuality
	forall (o in Objects, v in ASes, q in QualityLevels : q != MaxQualityLevel )
	cAlwaysHighQuality:
		ObjectCached[o][q][v] == 0;
	AlwaysHighQuality*/

	/*AllQualityLevels
	forall (o in Objects, v in ASes, q1 in QualityLevels : q1!=0, q2 in QualityLevels: q2!=0)
	cAllQualityLevels:
		ObjectCached[o][q1][v] == ObjectCached[o][q2][v];
	AllQualityLevels*/

	/*DedicatedCache
	forall ( sourceAS in ASes, q in QualityLevels )
	cDedicatedCache:
	  	sum ( o in Objects ) ( ObjectCached[o][q][sourceAS] * CacheSpacePerQuality[q] ) <= MaxCacheStorageAtSingleAS[sourceAS] / ( card(QualityLevels) - 1);
		// I substract -1 from the cardinality of QualityLevels because q=0 is not a real quality level
	DedicatedCache*/

	/*PropDedCache
	forall ( sourceAS in ASes, q in QualityLevels )
	cPropDedCache:
	  	sum ( o in Objects ) ( ObjectCached[o][q][sourceAS] * CacheSpacePerQuality[q] ) <= MaxCacheStorageAtSingleAS[sourceAS] * CacheSpacePerQuality[q] / sum ( qq in QualityLevels : qq!=0 ) CacheSpacePerQuality[qq];
		// I substract -1 from the cardinality of QualityLevels because q=0 is not a real quality level
	PropDedCache*/


	/*
		We may try to add this constraint to see if CPLEX goes faster:

		z_{v_s}^{o,q,v_d} , w_{v_s}^{o,q,v_d}, y_e^{o,q,v_d} \le d^{o,q,v_d}
	The last equation means that: no source $v_s$ can provide to users of $v_d$ more rate than the requested, either in the role of cache or in the role of server. Moreover, in a link, we cannot find more rate directed to $v_d$ than the rate requested by users of $v_d$. I guess this constraint can guide CPLEX to avoid searching solutions that are ``useless''. For example, with this constraint, we immediately tell to CPLEX: look, don't waste your time in allocating traffic at quality 0, because, in any case, its rate is 0.
	*/


	/*
		We may impose an additional constraint to force the system to serve all the requests, whereas, as the model is now, it may prefer to serve some requests at high quality neglecting others. Or we may impose to serve a percentage of the requests.
	*/


	/*		
		\subsection{Non-cooperazione tra gli AS}

		E' facile aggiungere dei vincoli per prevenire la cooperazione tra gli AS. Per farlo basta cambiare il bilanciamento dei flussi, rimuovere (\ref{eq:flowBalance}), ed aggiungere(\ref{eq:flowBalanceNonCoop}).

		\small
		\begin{flalign}
			& z^{o,q,v_d}_{v_s} + \sum\limits_{e \in BS(v_s)}{y^{o,q,v_d}_{e}} = \\
			& \sum\limits_{e \in FS(v_s)}{y^{o,q,v_d}_{e}} & \forall o \in O, q \in Q, v_s \in V, v_d \in V, v_s \neq v_d \label{eq:flowBalanceNonCoop}
		\end{flalign}
		\normalsize
	*/


}

// ################################
// #### FUNCTION DEFINITIONS ######
// ################################
execute DEFINING_FUNCTIONS
{
	function compute_requests_for_each_object()
	{
		if (!is_requests_for_each_object_computed)	
		{
			//{ FIND NUMBER OF REQUESTS FOR EACH OBJECT
			for (var r in ObjRequests )
				requests_for_each_object[r.object] += r.numOfObjectRequests;
				
			is_requests_for_each_object_computed = 1;
		}
		return requests_for_each_object;
	}
	
	function compute_total_requests()
	{
		if (!is_total_requests_computed)
		{
			total_requests = 0;	
			for (var r in ObjRequests )
				total_requests += r.numOfObjectRequests;
			is_total_requests_computed = 1;
		}
		return total_requests;
			
	}
	
	function compute_total_utility()
	{
		if( !is_total_utility_computed)
		{
		  	for (var r in ObjRequests) for (q in QualityLevels)
		  		total_utility += ObjectRequestsServed[r][q] * UtilityPerQuality[q];
		  	is_total_utility_computed = 1;
  		}
  		return total_utility;  		
	}
}	


//########################################################
//######## PRINT RESULTS #################################
//########################################################
execute DISPLAY 
{
  	//###################################
  	//### Print objective function
  	//###################################
	var max_utility = -1000;
	for (q in QualityLevels)
		if(UtilityPerQuality[q] > max_utility) max_utility=UtilityPerQuality[q];

  	var total_utility = 0; var tot_reqs = 0; var avg_utility = 0; 
  	for (var r in ObjRequests) for (q in QualityLevels)
	{
  		total_utility += ObjectRequestsServed[r][q] * UtilityPerQuality[q]; 
	}
	for (var r in ObjRequests) tot_reqs += r.numOfObjectRequests;
	avg_utility = total_utility / tot_reqs;
	//{ CHECK
		if ( avg_utility > max_utility )
		{
			writeln("ERROR: avg_utility > max_utility\n");
			exit;
		}else
			writeln("avg_utility = ", avg_utility);
	//} CHECK

  	var f = new IloOplOutputFile("objective.csv");
  	f.open;
	f.write("avg_utility\n");
  	f.write(avg_utility,"\n");
  	f.close;

/*
  	var f = new IloOplOutputFile("total_utility.csv");
  	f.open;
	f.write("total_utility\n");
  	f.write(total_utility,"\n");
  	f.close;
*/

  	//###################################*
  	//### Print origin_of_service #######*
  	//###################################*
  	// Print, for each quality, how many of the requests served at that quality in all the network
  	// come from a cache and how many come from e producer
	var f = new IloOplOutputFile("origin_of_service.csv");
	f.open;
	for (var q in QualityLevels) 
		if (q!= 0) f.write("#q",q,"_cache #q",q,"_prod ");
	f.write("tot_req\n");
	   	
	for (var q in QualityLevels)
  	{
  		if (q!=0)  	
  		{
	  		var RateServedByCache = 0;
	  		var RateServedByProducers = 0;
	  	
			for (var origin_as in ASes) for (var r in ObjRequests)
			{
				RateServedByCache += FlowServedByCache[r][q][origin_as];
				RateServedByProducers += FlowServedByProducers[r][q][origin_as];
			}
			f.write(RateServedByCache/RatePerQuality[q]," ",RateServedByProducers / RatePerQuality[q]," " );
 		}			
	}
	f.write(compute_total_requests() );
	f.close;



  	//###################################*
  	//### Print utility_contribution ####*
  	//###################################*
  	// Print how much utility comes from the set of caches and how much from the producer
	var f = new IloOplOutputFile("utility_contribution.csv");
	f.open;
	f.write("from_cache from_producer tot\n");
	
	var UtilityFromCache = 0;
	var UtilityFromProducers = 0;   	
	for (var q in QualityLevels)
  	{
  		if (q!=0)  	
  		{
  			var RateServedByCache = 0;
  			var RateServedByProducers = 0;
			for (var origin_as in ASes) for (var r in ObjRequests)
			{
				RateServedByCache += FlowServedByCache[r][q][origin_as];
				RateServedByProducers += FlowServedByProducers[r][q][origin_as];
			}
			UtilityFromCache += (RateServedByCache / RatePerQuality[q] ) * UtilityPerQuality[q];
			UtilityFromProducers += (RateServedByProducers / RatePerQuality[q] ) * UtilityPerQuality[q];  
 		}			
	}
	f.write(UtilityFromCache," ",UtilityFromProducers, " ", compute_total_utility() );
	f.close;




  	//###################################*
  	//### Print cached quality levels ###*
  	//###################################*
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



	

	 //########################################**
  	 //### Print cached quality levels per rank *
  	 //########################################**
  	 if (!IsRequestsForEachObjectComputed)
  	 	compute_requests_for_each_object();
  	 
	for (var q in QualityLevels)
	{
		if (q!=0)
		{	
			var f = new IloOplOutputFile("cached_at_q"+q+".csv");
			f.open;
			f.write("#rank requests");
			for (var as in ASes) f.write(" AS=",as);
			f.write("\n");
	
			for (var o in Objects)
			{
				f.write(o);
				f.write(" ",RequestsForEachObject[o]);
				for (var as in ASes)
					f.write(" ",ObjectCached[o][q][as]);
				f.write("\n");
			}
			f.close;
		}		
	}




	 //########################################**
  	 //### Print avg cached quality levels per rank *
  	 //########################################**
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


/*
	//###################################*
  	//### Print intersection ###########**
	//###################################*
	var f = new IloOplOutputFile("intersection.csv");
	f.open;
	f.write("#rank requests intersection\n");
	for (var o in Objects)
	{
		f.write(o," ",RequestsForEachObject[o]," ");
		var it_is_cached = 1;
		for (var as in ASes)
		{	
			if ( MaxCacheStorageAtSingleAS[as]>0 )
			{
				var it_is_cached_in_this_as = 0;
				for (var q in QualityLevels)
					it_is_cached_in_this_as += ObjectCached[o][q][as];
				it_is_cached = it_is_cached * it_is_cached_in_this_as;  
 			}
		}//as loop
		f.write( it_is_cached>0 ? 1:0);
		f.write("\n");
	} //o loop
	f.close;
*/


	//########################################**
  	//### Print how many requests per quality **
  	//########################################**
	// It prints the number of served object at each quality
	var total_requests = 0;

  	// Initialize the data structure
  	for (var q in QualityLevels)
  		HowManyRequestsPerQuality[q] = 0;
  		
  	// Populate the data structure
 	for (var r in ObjRequests)
		for(var q in QualityLevels)
		{
		 	HowManyRequestsPerQuality[q] += ObjectRequestsServed[r][q];
			total_requests += ObjectRequestsServed[r][q];
		}
	  	
  	// Print to file
	var f = new IloOplOutputFile("how_many_reqs_per_quality.csv");
	f.open;
	for (var q in QualityLevels)
		f.write("q",q, " ");
	f.write("\n");
	for (var q in QualityLevels)
		f.write(HowManyRequestsPerQuality[q] / total_requests, " ");
	f.write("\n");
	f.close;





	//########################################**
  	//### Print served quality levels per rank *
  	//########################################**
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



	//####################################
  	//### Print link load ################
  	//###################################*
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




/*
	//###################################*
  	//### Print cache sizes ##############
  	//###################################*
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
*/
}


