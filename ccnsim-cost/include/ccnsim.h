#ifndef __CCNSIM_H___
#define __CCNSIM_H___

#include <vector>
#include <omnetpp.h>
//<aa>
#include "error_handling.h"

// If SEVERE_DEBUG is enabled, overabundant checks will be performed in order to avoid inconsistent
// state. It will slow down the simulation (for example a run of 10 s disabling SEVERE_DEBUG
// may take 14 s when enabling it), but if you are considerably modifying 
// ccnSim source code, it is advisable to 
// enable it for some runs, just to check that there are not erroneous things happening.
// This does not affect in any way the results.
//#define SEVERE_DEBUG
//#define ADDITIONAL_INFO


#define UNDEFINED_VALUE -1
//</aa>

//System packets
#define CCN_I 100   //ccn interest 
#define CCN_D 200   //ccn data 
#define GHOST 5    //ghost interest

//Clients timers
#define ARRIVAL 300 //arrival of a request 
#define TIMER 400   //arrival of a request 

//Statistics timers
#define FULL_CHECK 2000
#define STABLE_CHECK 3000
#define END 4000
//<aa>
#define CACHE_DUMP 5000
//</aa>

//Typedefs
// {CATALOG FIELDS
	//There is an entry of this kind for each object. size indicates how many chunks compose that object
	//repos is a mask with a 1 in the i-th position if the object is present in the i-th repository
	typedef unsigned int info_t; //Catalog  entry [size|repos]

	//Size part within the catalog entry. It indicates how many chunks compose that object
	typedef unsigned short filesize_t;

	//<aa>	Each repo_t variable is used to indicate the set of repositories where
	//		a certain content is stored. A repo_t variable must be interpreted as a
	//		binary string. For a certain content, the i-th bit is 1 if and only if the
	//		content is stored in the i-th repository.
	//</aa>
	typedef unsigned short repo_t; //representation for the repository part within the catalog entry
// }CATALOG_FIELDS



typedef unsigned long interface_t; //representation of a PIT entry (containing interface information)

//Chunk fields
//representation for any chunk flying within the system. It represents a triple [name|number|representation]
//name is 32 bits, number 16 bits and representation 16 bits.
//Remember that each chunk can have different representations. For example, the same chunk of a video can be encoded
//at different bitrates and resolutions. In ccnSim you can have 16 different representations of the same chunk.
//However, for most simulation scenarios, a single representation per-chunk is enough.
typedef uint64_t chunk_t; 
typedef uint32_t name_t; //represents the name part of the chunk
typedef uint16_t cnumber_t; //represents the number part of the chunk
typedef uint16_t representation_mask_t;


//Useful data structure. Use that instead of cSimpleModule, when you deal with caches, strategy_layers, and core_layers
#include "client.h"
class abstract_node: public cSimpleModule{
    public:
	abstract_node():cSimpleModule(){;}

	virtual cModule *__find_sibling(std::string mod_name){
	    return getParentModule()->getModuleByRelativePath(mod_name.c_str());
	}

	virtual int __get_outer_interfaces(){
		severe_error(__FILE__,__LINE__,
				"In this version of ccnSim this method moved to strategy_layer::get_outer_interfaces()");
	    return 0;
	}

	bool __check_client(int interface)
	{
		severe_error(__FILE__,__LINE__,
				"In this version of ccnSim this method moved to strategy_layer::check_client(..)");
	    return false;
	}

	//<aa>	If there is a client attached to the specified interface, it will be returned. 
	//		Otherwise a null pointer will be returned
	client* __get_attached_client(int interface)
	{
		severe_error(__FILE__,__LINE__,"In this version of ccnSim this method has been removed");
		return NULL;
	}
	//</aa>

	virtual int getIndex()
	{
	    return getParentModule()->getIndex();
	}

};

//Macros
//--------------
//Chunk handling
//--------------
//Basically a chunk is a 64-bit integer composed by three parts: object id, 
//chunk_number and representation level
//<aa> The first 32 bits indicate the chunk_id, the other 16 bits the chunk_number and the last 
// 16 bits the representation level </aa>
#define ID_OFFSET               0
#define NUMBER_OFFSET           32
#define REPRESENTATION_OFFSET   48

//Bitmasks
#define ID_MSK                          ( (uint64_t) 0xFFFFFFFF << ID_OFFSET )
#define CHUNK_MSK                       ( (uint64_t) 0xFFFF << NUMBER_OFFSET)
#define REPRESENTATION_MSK      ( (uint64_t) 0xFFFF << REPRESENTATION_OFFSET)

//{ MACROS
	#define __id(h)                         ( ( h & ID_MSK )                >> ID_OFFSET) //get object id
	#define __chunk(h)                      ( ( h & CHUNK_MSK )             >> NUMBER_OFFSET )// get chunk number
	#define __representation_mask(h) ( ( h & REPRESENTATION_MSK )>> REPRESENTATION_OFFSET )// get representation

	//set object id <aa> (i.e. the id of the object this chunk is part of)
	#define __sid(h,id)   h = ( (h & ~ ID_MSK)   | ( (uint64_t ) id << ID_OFFSET)) 

	#define __schunk(h,c) h = ( (h & ~CHUNK_MSK) | ( (uint64_t ) c  << NUMBER_OFFSET)) //set chunk number

	//set the representation
	#define __srepresentation_mask(h,r)   h = ( (h & ~ REPRESENTATION_MSK)   | ( (uint64_t ) r << REPRESENTATION_OFFSET)) 
//} MACROS

inline chunk_t next_chunk (chunk_t c){

    cnumber_t n = __chunk(c);
    __schunk(c, (n+1) );
    return c;

}



//<aa>
// File statistics. Collecting statistics for all files would be tremendously
// slow for huge catalog size, and at the same time quite useless
// (statistics for the 12345234th file are not so meaningful at all)
// Therefore, we compute statistics only for the first __file_bulk files
// (see client.cc)
// </aa>
#define __file_bulk (content_distribution::perfile_bulk + 1)



//-----------
//PIT handling 
//-----------
//Each entry within a PIT contains a field that indicates through
//which interface the back-coming interest should be sent
//<aa>  This field is f, a bit string that contains a 1 in the i-th place
// if the i-th is set </aa>
//
#define __sface(f,b)  ( f = f | ((interface_t)1 << b ) ) //Set the b-th bit
#define __uface(f,b)  ( f = f & ~((interface_t)1<<b) ) //Unset the b-th bit
#define __face(f,b)   ( f & ((interface_t)1<<b) ) //Check the b-th bit
//
//
//

//---------------------------
//Statistics utility functions
//---------------------------
//Calculate the average of a vector of elements
template <class T>
double average(std::vector<T> v){
    T s =(T) 0;
    for (typename std::vector<T>::iterator i = v.begin(); i != v.end(); i++)
        s += *i;
    return (double) s * 1./v.size();
}


template <class T>
double variance(std::vector<T> v){

    T s = (T) 0;
    T ss = (T) 0;
    unsigned int N = v.size();

    for (typename std::vector<T>::iterator i = v.begin(); i != v.end(); i++){
                s += *i;
                ss += (*i)*(*i);
    }
    return (double)(1./N)* (sqrt(N*ss- s*s));

}
#endif

