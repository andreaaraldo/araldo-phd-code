/** Andrea Araldo says: this is my modified version of Leonardi's code (general_tree_original.c). I verified with diffuse that, when using pLRU, they give extactly the same results.
Modifications are embraced by tags <aa>.and </aa>.
*/

#include<stdio.h>
#include<stdlib.h>
#include<math.h>

//<aa>
#define SEVERE_DEBUG
//</aa>

#define  MAXITER   20
#define STAGES       1
#define DETAILEDPRINT   1
#define CATALOGUE    100001  // dimensione catalogo+1
#define  TREE_DEG    1.0   //grado albero
#define  Q           0.01   // parametro di qLRU

// Implements   LRU FIFO Random pLRU 
typedef enum policy {LRU,pLRU, CoA } policy;   //politoca usata   se usi qLRU -> ottieni LCP
policy  cache_pol;

// <aa> lam[o][s] rate of requests for object o seen at stage s </aa>
double lam[CATALOGUE][STAGES];

//<aa> p[o][s] probability that object o is present in the cache of stage s </aa>
double pin[CATALOGUE][STAGES];

double TC[STAGES], C[STAGES], phit[STAGES];

//<aa> sumzipf[s]: sum of rates of the cache at stage s. sumzipf[0] is the harmonic number of 
//	   Zipf distribution </aa>
double sumzipf[STAGES]; 

//<aa> 
// The results slightly change when changind this number, but are approximately the same.
// Indeed, the final values are obtained after the convergence of an iterative algorithm
double TC_init_factor = 0.3; //Leonardi's default was 0.3

// COST_AWARE STUFF{
#define EXT_LINKS 3
double* K_; // beta_multiplier (see compute_K(...) for more info)
double* obj_price; //obj_price[k] is the price of object k
// }COST_AWARE STUFF
//</aa> 


//<aa> Returns the harmonic number of the zipf </aa> 
double initizipf(double alpha, long CATALOG, int stage, double Lambda)
{
	 double sum;
	 long k;
	 sum=0.0;
		if(stage==0){
			for (k=1; k<=CATALOG; k++)
				sum+=pow((double )k,-  alpha);
		}else{ 
			for (k=1; k<=CATALOG; k++)
				sum+= lam[k][stage];
		}
	return sum;       
}    

//<aa> Returns the popularity of the k-th object </aa>
double zipfs_pop(long k, double alpha)
{
  return  pow((double )k,-alpha)/sumzipf[0]; 
}

//<aa> Returns the request frequency for object k entering stage stage </aa>
double compute_lam(double Lambda, long k, int stage, double alpha ) 
{
	double res;
		if(stage==0)  res=Lambda*zipfs_pop(k,alpha);
		else  res= ((double)TREE_DEG)*lam[k][stage-1]*(1.0- pin[k][stage-1]);
	return res;
}




// <aa> Returns the probability that the object k is in the cache at that stage </aa>
double  comp_pin(long k, long stage ) 
{
  double a= 1.0 - exp(-lam[k][stage]*TC[stage]);
  double q=Q;

  double return_value;

  //<aa>
  if (cache_pol==CoA)  
  {
	double K = *K_;
	q = Q*K*obj_price[k];
  }
  //</aa>

  if(cache_pol==LRU)
		return_value = a;
  //  if((cache_pol==FIFO)||((cache_pol==RANDOM)))   return Lambda*zipfs_pop(k,alpha)*TC/(1.0+ 	Lambda*zipfs_pop(k,alpha)*TC);
  else if(cache_pol==pLRU || cache_pol==CoA) 
		return_value = a*q/(1.0-a*(1-q));
  else{
	  printf(" caching policy not implemented\n");
	  exit(0);
  }

  //<aa>
  if (cache_pol == CoA && q == 0)
		return_value = 0;
  //</aa>

  #ifdef SEVERE_DEBUG
  if (isnan(return_value) )
  {
		printf("ERROR: the probability that object %ld is in cache is nan, q=%g\n", k, q);
		printf("a=%g, q=%g\n",a, q);
		exit(-1);
  }	
  #endif
  return return_value;    
}




double  cachedim(int stage, long CATALOG)
{
     long  k;
     double C;
     C=0.0;
     for (k=1; k<=CATALOG; k++){
        pin[k][stage]= comp_pin(k, stage ); 
		//printf( "k=%ld, s=%d, lam=%le,  pin=%le\n", k,stage, lam[k][stage], pin[k][stage]);
		C+=   pin[k][stage];
    }

	return C;
}


double  phitcond(long k, int stage ) 
{
  double return_value;
  double  a,b,c;
  double  q=Q;
  //<aa>
  if (cache_pol==CoA) 
  {
	double K = *K_;
	q = Q*K*obj_price[k];
  }
  //</aa>


  double TC2,TC1;
  if(cache_pol==LRU)
  {
		b=0.0;
		TC2=TC[stage];
		if(stage>0)
		{
		 TC1=TC[stage-1];
		     b= lam[k][stage]*TC2;
		 }else 
			TC1=0.0;
		 
		if(TC2>TC1)
			a= lam[k][stage]*(TC2-TC1);
		 else 
			a=0.0;

		if (stage>0)  
		{
			if (TREE_DEG==1) 
				return_value = 1.0 - exp (-a);
		    else 
				return_value = 1.0 - exp (-b);
		}else   
			return_value = 1.0 - exp (-a);
  }
	    //if((cache_pol==FIFO)||((cache_pol==RANDOM))) {
	    //   if(TC2>TC1)  return  lambda*(TC2-TC1)/(1.0 + lambda*(TC2-TC1)); else return 0.0;}
  else if(cache_pol==pLRU || cache_pol==CoA)
  {	
		TC2=TC[stage];
		if(stage>0)
		{
			TC1=TC[stage-1];
		}else 
			TC1=0.0;
	 
		if(TC2>TC1)
		{
			if(TREE_DEG==1) 
				a= (1.0-exp(-lam[k][stage]*(TC2-TC1)))*exp(-lam[k][stage]*(TC1))+ 
                	(1.0/TREE_DEG*(1.0-q)+(TREE_DEG-1.0)/TREE_DEG)*(1.0-exp(-lam[k][stage]*TC2));
		   else 
				a=1.0-exp(-lam[k][stage]*TC2);
		}else
		{
			if(TREE_DEG==1)
				a=(1.0-q)*(1.0-exp(-lam[k][stage]*TC2));
			else a  =1.0-exp(-lam[k][stage]*TC2);
		}

		b= 1.0-exp(-lam[k][stage]*TC2);
		if(stage>0)
		{
			return_value =  a*q/(1.0- a*(1.0-q));  
		}else 
		{
			return_value = b*q/(1.0-b*(1.0-q));
		}	
  }else{
	  printf(" caching policy not implemented\n");
	  exit(0);    
  }

  //<aa>
  if (cache_pol == CoA && q==0)
		return_value = 0;
  //</aa>

  #ifdef SEVERE_DEBUG
  if ( isnan(return_value) )
  {
		printf("ERROR: phitcond of object %ld is nan, q=%g\n", k, q);
		exit(-1);
  }

  if ( return_value == 0 && cache_pol != CoA )
  {
		printf("ERROR: phitcond of object %ld is 0, q=%g. This is not possible\n", k, q);
		exit(-1);
  }
  #endif

	return return_value;
}


// <aa> Returns the overall hit probability at that stage </aa>
double hitp(long CATALOG, int stage, double alpha)
{
	long k;
	double phit=0.0;
	double phitc; 
     
	for (k=1; k<=CATALOG; k++)
	{
		phitc=phitcond(k, stage );

		#ifdef SEVERE_DEBUG
		if (phitc == 0 && cache_pol != CoA)
		{
			printf("ERROR: Content %ld has phitc=0\n",k);
			exit(-1);
		}
		#endif


		if(stage>0) 
			phit += lam[k][stage]*phitc/sumzipf[stage]; 
        else 
			phit += zipfs_pop(k,alpha)*phitcond(k, stage );
		if(DETAILEDPRINT) 
			printf(" stage=%d phit(%ld)=%le price=%g\n",stage, k, phitc, obj_price[k]);
	}
	
	return phit;
}

//<aa> COST AWARE STUFF{
void generate_obj_price(long ctlg_size, double* price)
{
	obj_price = (double*) calloc(ctlg_size, sizeof(double) );
	int k; for(k=0; k<ctlg_size; k++)
	{
		int l = rand() % EXT_LINKS; // external link which the object lies behind
		obj_price[k] = price[l];
	}
}

// Beta multiplier K is such that beta(o) = K * obj_price[o]
void compute_K(double* prices, double* split_ratio)
{
	#ifdef SEVERE_DEBUG
	if (cache_pol != CoA)
	{
		printf("ERROR: It makes no sense to compute K if CoA is not used\n");
		exit (-1);
	}
	#endif

	// From formulas (7) and (8) of the 1st submission of TPDS
	double sum = 0;
	
	
	int i; for (i=0; i<EXT_LINKS; i++)
		sum += split_ratio[i] * prices[i];

	#ifdef SEVERE_DEBUG
	if (split_ratio[0]!=0.333 || split_ratio[1]!=0.333 || split_ratio[2]!=0.334)
	{
		printf("ERROR: split_ratio not valid\n");
		exit(-1);
	}

	if (sum == 0)
	{
		printf("%s:%d:ERROR: sum is 0\n",__FILE__, __LINE__);
		printf("Split ratio= ");
		for (i=0; i<EXT_LINKS; i++)
			printf("%g ", split_ratio[i]);
		printf("\n");

		printf("Prices = ");
		for (i=0; i<EXT_LINKS; i++)
			printf("%g ", prices[i]);
		printf("\n");

		exit(-1);
	}
	#endif

	K_ = (double*) calloc(1,sizeof(double) );
	*K_ = 1/sum;
}
//</aa> }COST AWARE STUFF



main(int argc, char *argv[])
{

  if ( argc != 3 ) /* argc should be 1 for correct execution */
  {
        /* We print argv[0] assuming it is the program name */
        printf( "usage: %s <priceratio> <seed>\n", argv[0] );
		exit(-1);
  }

  double price_ratio = atof(argv[1] );
  int seed = atoi(argv[2] );
  srand(seed);

  int i,s,iter;
  double phit_tot,adist;
  long CATALOG,k;
  double Ctarg[STAGES], TC1, TC2;
  double alpha=1.0;
  double Lambda=100.0;
  double cache_size = 1000;
  cache_pol=LRU;
  CATALOG=CATALOGUE-1;
  //<aa>
  double price[EXT_LINKS] = {0, 1,price_ratio}; // Prices of free, cheap and expensive links
  double split_ratio[EXT_LINKS] = {0.333, 0.333, 0.334};
  //</aa>



	//<aa> COST_AWARE STUFF{
	generate_obj_price(CATALOG, price);

	if (cache_pol == CoA){
		compute_K(price, split_ratio);
	}
	//<//aa> }COST_AWARE STUFF

	sumzipf[0]=initizipf(alpha,CATALOG,0,Lambda); 
	for(s=0; s<STAGES; s++)
	Ctarg[s]=cache_size;        //*pow(2.0,s);    // Dimensione cache...
  
	printf ("CATALOG=%ld cache_size=%g alpha=%lf Lambda=%g cache_pol=%d\n",
		CATALOG, cache_size, alpha, Lambda,cache_pol);
	printf("See at the end line the resuming results \n");
  
   
  
  
	for(i=0; i<1;i++)
    {
		phit_tot=0.0;
		adist=0.0;
	for(s=0; s<STAGES; s++)
	{
		printf("Entering stage %d\n",s);
		// <aa> I initialize TC to an arbitrary value. I will adjust it later. See following line
		//		to grasp the procedure </aa>
	    TC[s]= TC_init_factor/pow((double)TREE_DEG, (double)s)*Ctarg[s]/Lambda;
	    for (k=1; k<=CATALOG; k++)
		{
			lam[k][s]=compute_lam(Lambda, k, s,alpha);
                   // printf("lam[%ld][%d]=%le\n",k,s,lam[k][s]);
	    } 
	    if(s>0) sumzipf[s]=initizipf(alpha,CATALOG,s,Lambda);
	  //  printf("s=%d sumzipf=%le\n", s,sumzipf[s]);
	    iter=0;
	    do{   
			//<aa>	Fixing a value of TC, I obtained a value of 'fake cache size'. Increasing
			//		TC increases the fake cache size. I iteratively try to increase TC until 
			//		the fake cache size exceeds the real cache size. </aa>
			C[s]=cachedim(s,CATALOG);        

			TC[s]=TC[s]*2.0;
			iter++;
	    } while(C[s]<Ctarg[s]&&(iter<MAXITER));
	    if(iter==1){ 
			printf("error TC[%d]=%lf  too large",s, TC[s]);
			    exit(0);
	    }
	    if(iter==MAXITER){ 
			printf("error TC[%d]=%lf  too small\n",s, TC[s]);
			    exit(0);
	    }
	    TC2=TC[s]/2.0;
	    TC1=TC[s]/4.0;
		//printf("before the do %lf %lf\n",TC1,TC2);
	    do{
			TC[s]=(TC1+TC2)/2.0;                    
			C[s]=cachedim(s,CATALOG);       
			if (C[s]<Ctarg[s]) 
				TC1=TC[s];
			else TC2=TC[s];
				// printf("%lf %lf %lf  %lf \n",C,TC, TC1, TC2);
	    }while (fabs(C[s]-Ctarg[s])/Ctarg[s]>0.001);

	    phit[s]=hitp(CATALOG,s,alpha);
	    phit_tot+= phit[s]*(1.0-phit_tot);
	    adist+= phit[s]*(s+1);
	}

	//<aa> Print resume </aa>
	adist+=(STAGES+1)*(1.0-phit_tot);
	printf("num_stages=%d\t",STAGES);
	for(s=0; s<STAGES;s++)
	    printf(" csize_of_stage_%d=%lf \t phit_of_stage_%d=%lf \t TC_of_stage_%d=%lf\t", 
				s, C[s], s, phit[s], s, TC[s]);     
	printf("phit_tot=%lf\t adist=%lf\n",phit_tot, adist);
	fflush(stdout);

	//<aa> What is the purpose of these lines? </aa>
	for(s=0; s<STAGES; s++)
	 Ctarg[s]=Ctarg[s]*2.0;
    }
}
