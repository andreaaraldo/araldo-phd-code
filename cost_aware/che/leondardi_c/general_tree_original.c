#include<stdio.h>
#include<stdlib.h>
#include<math.h>

#define  MAXITER   20
#define STAGES       1
#define DETAILEDPRINT   1
#define CATALOGUE    100001  // dimensione catalogo+1
#define  TREE_DEG    1.0   //grado albero
#define  Q           0.01   // parametro di qLRU

// Implements   LRU FIFO Random pLRU 
typedef enum policy {LRU,pLRU } policy;   //politoca usata   se usi qLRU -> ottieni LCP
policy  cache_pol;


double lam[CATALOGUE][STAGES], pin[CATALOGUE][STAGES], TC[STAGES], C[STAGES], phit[STAGES];

double sumzipf[STAGES]; 
 
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


double zipfs_pop(long k, double alpha)
{
  return  pow((double )k,-alpha)/sumzipf[0]; 
}


double compute_lam(double Lambda, long k, int stage, double alpha ) {
double res;
    if(stage==0)  res=Lambda*zipfs_pop(k,alpha);
    else  res= ((double)TREE_DEG)*lam[k][stage-1]*(1.0- pin[k][stage-1]);
return res;
}

double  comp_pin(long k, long stage ) 
{
  double a= 1.0 - exp(-lam[k][stage]*TC[stage]);
  double q=Q;
  if(cache_pol==LRU)  return  a;
//  if((cache_pol==FIFO)||((cache_pol==RANDOM)))   return Lambda*zipfs_pop(k,alpha)*TC/(1.0+ Lambda*zipfs_pop(k,alpha)*TC);
  if(cache_pol==pLRU)  return  a*q/(1.0-a*(1-q));
  printf(" caching policy not implemented\n");
  exit(0);    
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
  double  a,b,c;
  double  q=Q;
  double TC2,TC1;
  if(cache_pol==LRU){
     b=0.0;
     TC2=TC[stage];
     if(stage>0){
	 TC1=TC[stage-1];
         b= lam[k][stage]*TC2;
     }else TC1=0.0;
     if(TC2>TC1)
	a= lam[k][stage]*(TC2-TC1);
     else a=0.0;
      if (stage>0)  {if (TREE_DEG==1) return 1.0 - exp (-a);
                       else return 1.0 - exp (-b);}
             else   return 1.0 - exp (-a);
    }
	    //if((cache_pol==FIFO)||((cache_pol==RANDOM))) {
	    //   if(TC2>TC1)  return  lambda*(TC2-TC1)/(1.0 + lambda*(TC2-TC1)); else return 0.0;}
     if(cache_pol==pLRU)
     {
               TC2=TC[stage];
               if(stage>0){
	          TC1=TC[stage-1];
               }else TC1=0.0;
	 
	       if(TC2>TC1){
                   if(TREE_DEG==1) 
			a= (1.0-exp(-lam[k][stage]*(TC2-TC1)))*exp(-lam[k][stage]*(TC1))+ 
                	(1.0/TREE_DEG*(1.0-q)+(TREE_DEG-1.0)/TREE_DEG)*(1.0-exp(-lam[k][stage]*TC2));
		   else a=1.0-exp(-lam[k][stage]*TC2);
	       }else{ if(TREE_DEG==1)  a=(1.0-q)*(1.0-exp(-lam[k][stage]*TC2));
	               else a  =1.0-exp(-lam[k][stage]*TC2);          
	       }
	        b= 1.0-exp(-lam[k][stage]*TC2);
		if(stage>0){
		       return  a*q/(1.0- a*(1.0-q));  
	         } else 
		 {
	               return b*q/(1.0-b*(1.0-q));
		 }	
     }	 
    printf(" caching policy not implemented\n");
    exit(0);    
}



double hitp(long CATALOG, int stage, double alpha)
{
     long k;
     double phit=0.0;
     double phitc; 
     
     for (k=1; k<=CATALOG; k++){
       phitc=phitcond(k, stage );
       if(stage>0) phit += lam[k][stage]*phitc/sumzipf[stage]; 
        else phit += zipfs_pop(k,alpha)*phitcond(k, stage );
      if(DETAILEDPRINT) printf(" stage=%d phit(%ld)=%le\n",stage, k, phitc);
     }   

return phit;}





main()
{
int i,s,iter;
double phit_tot,adist;
long CATALOG,k;
  double Ctarg[STAGES], TC1, TC2;
  double alpha=1.0;
  double Lambda=100.0;
  cache_pol=pLRU;
  CATALOG=CATALOGUE-1;
  sumzipf[0]=initizipf(alpha,CATALOG,0,Lambda); 
  for(s=0; s<STAGES; s++)
   Ctarg[s]=1000;        //*pow(2.0,s);    // Dimensione cache...
  
  printf ("CATALOG=%ld alpha=%lf\n",CATALOG,alpha);
  printf("stages {C[]\t  Phit[]\t TC[]} \t phit_tot\t adist \n");
  
   
  
  
    for(i=0; i<1;i++)
    {
	phit_tot=0.0;
	adist=0.0;
	for(s=0; s<STAGES; s++){
	    TC[s]= 0.3/pow((double)TREE_DEG, (double)s)*Ctarg[s]/Lambda;
	    for (k=1; k<=CATALOG; k++){
		lam[k][s]=compute_lam(Lambda, k, s,alpha);
                   // printf("lam[%ld][%d]=%le\n",k,s,lam[k][s]);
	    } 
	    if(s>0) sumzipf[s]=initizipf(alpha,CATALOG,s,Lambda);
	  //  printf("s=%d sumzipf=%le\n", s,sumzipf[s]);
	    iter=0;
	    do{    
		C[s]=cachedim(s,CATALOG);        
		TC[s]=TC[s]*2.0;
		iter++;
	    } while(C[s]<Ctarg[s]&&(iter<MAXITER));
	    if(iter==1){ 
		printf("error TC[%d]  too large",s);
	        exit(0);
	    }
	    if(iter==MAXITER){ 
		printf("error TC[%d]  too small",s);
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
	 adist+=(STAGES+1)*(1.0-phit_tot);
	printf("%d\t",STAGES);
	for(s=0; s<STAGES;s++)
	    printf(" %lf \t %lf \t %lf\t", C[s], phit[s], TC[s]);     
	printf("%lf\t %lf\n",phit_tot, adist);
	fflush(stdout);
	for(s=0; s<STAGES; s++)
	 Ctarg[s]=Ctarg[s]*2.0;
    }
}
