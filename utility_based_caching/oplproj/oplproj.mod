/*********************************************
 * OPL 12.5 Model
 * Author: araldo_local
 * Creation Date: Dec 18, 2014 at 1:37:10 PM
 *********************************************/
/* <aa>
 * This is a bbbbb
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
int V_card      = ...;
int O_BF_card   = ...;
int O_OF_card   = ...;
int O_LQ_card   = ...;
int O_HQ_card   = ...;
int Categories_card = ...;

/*********************************************************
* Range variables
*********************************************************/
setof(int) Q = ...;

range V      = 1..V_card;
range O_BF   = 1..O_BF_card;
range O_OF   = O_BF_card+1 .. O_BF_card+O_OF_card;
range O_LQ   = O_BF_card+O_OF_card+1 .. O_BF_card+ O_OF_card+ O_LQ_card ;
range O_HQ   = O_BF_card+ O_OF_card+ O_LQ_card+1 .. O_BF_card+ O_OF_card+ O_LQ_card+O_HQ_card ;
range O      = 1 .. O_BF_card+ O_OF_card+ O_LQ_card+O_HQ_card;
range O_F    = 1..O_BF_card+O_OF_card;
range O_V    = O_BF_card+O_OF_card+1 .. O_BF_card+ O_OF_card+ O_LQ_card+O_HQ_card;
range Categories = 1..Categories_card; // corresponding to BF, OF, LQ, HQ


/*********************************************************
* Input Parameters
*********************************************************/
int a[O][V]				=...;
int s[Q]				=...;	
float U[Q]				=...;
float b[V][V]				=...;
float K					=...;
float M					=...;
float hmin[Q]				=...;
float hmax[Q]				=...;
float S					=...;

float d[O][V]				= ...;
float bar_r_BF				= ...;
float bar_bar_r_BF			= ...;
float bar_r_OF				= ...;
float bar_bar_r_OF			= ...;
float m_BF				= ...;
float m_prime_BF				= ...;
float m_OF				= ...;
float m_prime_OF				= ...;



/*********************************************************
* Intermediate variables
*********************************************************/
float TotalDemandInverse;
execute
{
		var TotalDemand = 0;
		for (var o in O)
		{		
			for (var a_ in V)
				TotalDemand += d[o][a_];
		}
		TotalDemandInverse = 1/TotalDemand;
};


/*********************************************************
* Decision variables
*********************************************************/
dvar boolean x[O][V][Q];
dvar boolean I[O][V][Q];
dvar float+  y[O][V][V][V];
dvar float+  y_to_u_q_dependent[O][V][Q];
dvar float+  y_to_u[O][V];
dvar float+  y_from_source[O][V][Q];
dvar float+  r[O][V];
dvar float+  v[O_F][V];
dvar float+  w[O_F][V];
dvar boolean  z[O_F][V];



/*********************************************************
* ILP MODEL: Objective Function
*********************************************************/

dexpr float u_BF = 
    sum (o in O_BF, a_ in V)
    (
      d[o][a_] *
      m_BF * v[o][a_] + m_prime_BF * (w[o][a_] - bar_r_BF)
    );

dexpr float u_OF = 
    sum (o in O_OF, a_ in V)
    (
      d[o][a_] *
      m_OF * v[o][a_] + m_prime_OF * (w[o][a_] - bar_r_OF)
    );
    
dexpr float u_V = 
    sum ( o in O_V, a_ in V, q in Q)
    (
      I[o][a_][q] * d[o][a_] * U[q]
    );

maximize u_BF + u_OF + u_V;

/*********************************************************
* ILP MODEL: Constraints
*********************************************************/

subject to {
	forall( o in O, i in V, q in Q)
	ct2:
		x[o][i][q] >= a[o][i];


	forall( o in O, a_ in V)
	ct3:
		sum( q in Q ) I[o][a_][q] == 1;


	forall( o in O_F, q in Q diff {1}, i in V, a_ in V )
	ct4:
		x[o][i][q] == I[o][a_][q] == 0;
		
	forall( o in O_LQ, q in Q diff {2}, i in V, a_ in V )
	ct5:
		x[o][i][q] == I[o][a_][q] == 0;

		
	forall( o in O_HQ,  i in V, a_ in V )
	ct6:
		x[o][i][1] == I[o][a_][1] == 0;


	ct7:
		sum(i in V) sum( o in O ) sum(q in Q) (x[o][i][q] - a[o][i] ) * s[q] <= S;


	forall(i in V, j in V)
	ct8:
		sum( o in O ) sum (a in V) y[o][a][i][j] <= b[i][j];
		
	forall( o in O, q in Q, a_ in V)
	ct9:
	  	y_to_u_q_dependent[o][a_][q] <= K * I[o][a_][q];
	  	
	
	forall( o in O, a_ in V)
	ct10:
	  	y_to_u[o][a_] ==sum( q in Q) y_to_u_q_dependent[o][a_][q];
	  	
	forall( o in O, a_ in V, i in V, q in Q )
	ct11:
	  	sum( j in V ) y[o][a_][i][j] + y_to_u[o][i] == 
	  	sum( k in V ) y[o][a_][k][i] + sum (q in Q) y_from_source[o][i][q];
	  	
	forall( i in V, o in O, q in Q )
	ct12:
	  	y_from_source[o][i][q] <= M * x[o][i][q];
	
	forall( o in O, a_ in V )
	ct13:
		d[o][a_] * r[o][a_] == y_to_u[o][a_];
		
	forall( o in O, a_ in V )
	ct13_bis:
		r[o][a_] <= M;

	forall ( o in O, a_ in V, q in Q)
	ct14:
	  	I[o][a_][q] * hmin[q] <= r[o][a_];	  	
/*
	forall ( o in O, a_ in V, q in Q)
	ct15:
	  	r[o][a_] <= I[o][a_][q] * hmax[q];
*/	  	
	forall ( o in O_F, a_ in V)
	ct18:
		r[o][a_] == v[o][a_] + w[o][a_];
		
	forall ( o in O_BF, a_ in V)
	ct19:
		bar_r_BF * z[o][a_] <= v[o][a_];
		
	forall ( o in O_BF, a_ in V)
	ct19_bis:
		v[o][a_] <= bar_r_BF;
		
	forall ( o in O_OF, a_ in V)
	ct20:
		bar_r_OF * z[o][a_] <= v[o][a_];
		
	forall ( o in O_OF, a_ in V)
	ct20_bis:
		v[o][a_] <= bar_r_OF;
		
	forall ( o in O_BF, a_ in V)
	ct21:
		w[o][a_] <= z[o][a_] * (bar_bar_r_BF - bar_r_BF);
		
	forall ( o in O_OF, a_ in V)
	ct22:
		w[o][a_] <= z[o][a_] * (bar_bar_r_OF - bar_r_OF);

}

main {
  thisOplModel.generate();
  cplex.solve();
  var ofile = new IloOplOutputFile("results.txt");
  ofile.writeln(thisOplModel.printExternalData());
  ofile.writeln(thisOplModel.printInternalData());
  ofile.writeln(thisOplModel.printSolution());
  ofile.close();
}

execute DISPLAY {
    writeln("Optimization results\n\n");

    var f_border_router_cache_sizes = new IloOplOutputFile("replica_placement.csv");
    f_border_router_cache_sizes.open;
    f_border_router_cache_sizes.close;

/*********************************************************
* TESTS
*********************************************************/
    /////////// INPUT VERIFICATION
    // b[i][i] must be 0
    
    // hmin[q] == hmax[q], if q>0
    
    // At least one repository must provide the content.
    
    // The cardinality of O must be the sum of cardinalities of O_BF O_OF O_LQ O_HQ.

    /////////// SOLUTION CORRECTNESS VERIFICATION

    // Demand should be satisfied

}