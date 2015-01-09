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
int Ishare				=...;
int a[O][V]				=...;
float s[Q]				=...;	
float U[Q]				=...;
float b[V][V]				=...;
float K					=...;
float M					=...;
float hmin[Q]				=...;
float hmax[Q]				=...;
float Stot				=...;
float Ssingle			=...;

float d[O][V]				= ...;
float bar_r_BF				= ...;
float bar_bar_r_BF			= ...;
float bar_r_OF				= ...;
float bar_bar_r_OF			= ...;
float m_BF				= ...;
float m_prime_BF				= ...;
float m_OF				= ...;
float m_prime_OF		= ...;
float delta_Utot		= ...;
float delta_Ytot		= ...;


// eq (36)
float hat_U_tot = 
	sum(o in O_LQ, a_ in V) ( U[2] * d[o][a_] )+
	sum(o in O_HQ, a_ in V) ( U[4] * d[o][a_] )+
	sum(o in O_BF, a_ in V) ( (m_BF * bar_r_BF + m_prime_BF * bar_bar_r_BF) * d[o][a_] )+
	sum(o in O_OF, a_ in V) ( (m_OF * bar_r_OF + m_prime_OF * bar_bar_r_OF) * d[o][a_] )
;

// eq (37)
float hat_Y_tot =
	sum (i in V, j in V) b[i][j];

// eq (40)
float M[O][V];
for (o in O_LQ, a_ in V) M[o][a] = hmin[2] * d[o][a];
for (o in O_HQ, a_ in V) M[o][a] = hmin[4] * d[o][a];
for (o in O_BF, a_ in V) M[o][a] = bar_bar_r_BF * d[o][a];
for (o in O_OF, a_ in V) M[o][a] = bar_bar_r_OF * d[o][a];

//eq (43)
float alpha = delta_Utot / hat_Y_tot;

//eq (44)
float beta = delta_Ytot / hat_U_tot;





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
* Input checks
*********************************************************/
int error = 0;

execute INPUT_CHECKS{
	for (i in V)
		if (b[i][i] != 0){
			writeln ("ERROR: input incorrect. b[i][i] must be 0");
			error = 1;
		}
}


/*********************************************************
* Decision variables
*********************************************************/
dvar boolean l[O][Q];
dvar boolean x[O][V][Q];
dvar boolean I[O][V][Q];
dvar float+  y[O][V][V][V];
dvar float+  f_usr[O][V][V][Q];
dvar float+  y_usr[O][V][V];
dvar float+  f_src[O][V][V][Q];
dvar float+  y_src[O][V][V];
dvar float+	 y_tot[V][V];
dvar float+  r[O][V];
dvar float+  v[O_F][V];
dvar float+  w[O_F][V];
dvar boolean  z[O_F][V];
dvar float+  u[V];
dvar float+ Ytot;
dvar float+ Utot;



/*********************************************************
* ILP MODEL: Objective Function
*********************************************************/
//dexpr float obj_fun = Utot - alpha * Ytot;	//UTILITY
dexpr float obj_fun = -Ytot+ beta * Utot;		//BANDWIDTH

maximize obj_fun;


/*********************************************************
* ILP MODEL: Constraints
*********************************************************/

subject to {

	forall( o in O_F)
	ct5_a:
		l[o][1] == 1;
	forall( o in O_F, q in Q diff {1})
	ct5_b:
		l[o][q] == 0;
	forall( o in O_LQ)
	ct5_c:
		l[o][2] == 1;
	forall( o in O_LQ, q in Q diff {2})
	ct5_d:
		l[o][q] == 0;
	forall( o in O_HQ, q in Q diff {1})
	ct5_e:
		l[o][q] == 1;
	forall( o in O_HQ)
	ct5_f:
		l[o][1] == 0;

		

	forall( o in O, i in V, q in Q)
	ct7:
		x[o][i][q] >= l[o][q] * a[o][i];


	forall( o in O, a_ in V)
	ct8:
		d[o][a_] *sum( q in Q ) I[o][a_][q] == d[o][a_];


	forall( o in O, q in Q, i in V)
	ct9:
		x[o][i][q] <= l[o][q];
		

	forall( o in O, q in Q, a_ in V)
	ct10:
		I[o][a_][q] <= l[o][q];


	forall( i in V)
	ct11:
		sum( o in O ) sum(q in Q) ( (x[o][i][q] - a[o][i] * l[o][q] ) * s[q] )<= Ssingle;

		
	ct12:
		sum( i in V ) sum( o in O ) sum(q in Q) ( (x[o][i][q] - a[o][i] * l[o][q] ) * s[q] )
		<= Stot;


	forall(i in V, j in V)
	ct13:
		sum( o in O ) sum (a in V) y[o][a][i][j] == y_tot[i][j];


	forall(i in V, j in V)
	ct14:
		y_tot[i][j] <= b[i][j];


	forall( o in O, a_ in V, i in V, q in Q)
	ct15:
		(a_-i) * f_usr[o][a_][i][q] == 0;


	forall( o in O, q in Q, a_ in V)
	ct16:
	  	f_usr[o][a_][a_][q] <= K * I[o][a_][q];
	
	
	forall( o in O, q in Q, a_ in V, i in V)
	ct17:
	  	f_src[o][a_][i][q] <= K * I[o][a_][q];
	  	
	 
	forall( a_ in V, i in V, o in O, q in Q)
	ct18:
		f_src[o][a_][i][q] <= M[o][a_] * x[o][i][q];


	forall( o in O, a_ in V, i in V)
	ct19:
	  	y_usr[o][a_][i] == sum( q in Q) f_usr[o][a_][i][q];


	forall ( o in O, a_ in V, i in V)
	ct20:
		y_src[o][a_][i] == sum (q in Q) f_src[o][a_][i][q];

	
	forall( a_ in V, i in V, o in O)
	ct21:
		(a_-i) * (1-a[o][i] ) * (Ishare - 1) * y_src[o][a_][i] == 0;


	forall ( o in O, a_ in V, i in V)
	ct22:
		y[o][a_][a_][i] == 0;


	forall( o in O, a_ in V, i in V)
	ct23:
	  	y_usr[o][a_][i] + sum( j in V ) y[o][a_][i][j]  == 
	  	sum( k in V ) y[o][a_][k][i] + y_src[o][a_][i];

	  	
	forall( o in O, a_ in V)
	ct24:
		y_usr[o][a_][a_] == sum(i in V) y_src[o][a_][i];

		
	forall( o in O, a_ in V )
	ct25:
		d[o][a_] * r[o][a_] == y_usr[o][a_][a_];
		

	forall( o in O, a_ in V )
	ct26:
		r[o][a_] <= y_usr[o][a_][a_];


	forall ( o in O, a_ in V, q in Q)
	ct27:
	  	I[o][a_][q] * hmin[q] <= r[o][a_];

	  	
	forall ( o in O_F, a_ in V)
	ct29:
		r[o][a_] == v[o][a_] + w[o][a_];
		

	forall ( o in O_BF, a_ in V)
	ct30:
		bar_r_BF * z[o][a_] <= v[o][a_];
		
	forall ( o in O_BF, a_ in V)
	ct30_bis:
		v[o][a_] <= bar_r_BF;
		
		
	forall ( o in O_OF, a_ in V)
	ct31:
		bar_r_OF * z[o][a_] <= v[o][a_];
		
	forall ( o in O_OF, a_ in V)
	ct31_bis:
		v[o][a_] <= bar_r_OF;
		
		
	forall ( o in O_BF, a_ in V)
	ct32:
		w[o][a_] <= z[o][a_] * (bar_bar_r_BF - bar_r_BF);
		
	forall ( o in O_OF, a_ in V)
	ct33:
		w[o][a_] <= z[o][a_] * (bar_bar_r_OF - bar_r_OF);


	forall ( a_ in V)
	ct35:
		u[a_] == 
		sum (o in O_V) sum( q in Q) I[o][a_][q] * d[o][a_] * U[q] +
		sum (o in O_OF)( 
		      d[o][a_] *
		      m_OF * v[o][a_] + m_prime_OF * w[o][a_]
    	)+
	    sum (o in O_BF)
		(
		  d[o][a_] *
		  m_BF * v[o][a_] + m_prime_BF * (w[o][a_] - bar_r_BF)
		);

	ct36:
		Utot == sum( a_ in V ) u[a_];

	ct37:
		Ytot == sum(i in V) sum(j in V) y_tot[i][j];

		
}

main {
  thisOplModel.generate();
  if (! thisOplModel.error)
  {
	  if (cplex.solve() )
	  {
		  var ofile = new IloOplOutputFile("results.txt");
		  ofile.writeln(thisOplModel.printExternalData());
		  ofile.writeln(thisOplModel.printInternalData());
		  ofile.writeln(thisOplModel.printSolution());
		  ofile.close();
	  }
  }
}

execute DISPLAY {
    writeln("Optimization results\n\n");

    var f_border_router_cache_sizes = new IloOplOutputFile("replica_placement.csv");
    f_border_router_cache_sizes.open;
    f_border_router_cache_sizes.close;

/*********************************************************
* TESTS
*********************************************************/
    
    // hmin[q] == hmax[q], if q>0
    
    // At least one repository must provide the content.
    
    // The cardinality of O must be the sum of cardinalities of O_BF O_OF O_LQ O_HQ.

	// The rows of d must be O_card, the columns V_card


    /////////// SOLUTION CORRECTNESS VERIFICATION

    // Demand should be satisfied

}
