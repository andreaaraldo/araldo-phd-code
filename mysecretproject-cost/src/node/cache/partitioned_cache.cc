//<aa>
#include "partitioned_cache.h"
#include "ccnsim.h"
#include <stdlib.h>
#include <iostream>   // std::cout
#include <string>     // std::string, std::to_string

Register_Class(partitioned_cache);

void partitioned_cache::initialize()
{
	base_cache::initialize();
	num_of_partitions = content_distribution::get_repr_h()->get_num_of_representations();
	subcaches = (lru_cache**) malloc(num_of_partitions * sizeof(lru_cache*) );

	//{ PARTITION SET UP
	// cache_slots is the number of chunk that we can store at high quality.
	unsigned possible_lowest_repr_chunks = cache_slots*
		content_distribution::get_repr_h()->get_storage_space_of_representation(num_of_partitions);
	unsigned subcache_size[num_of_partitions];	// Number of objects at the relative quality that each subcache
												// can host

	const char* equality = par("equality");
	if ( strcmp(equality, "space")==0 ) 
	{	// All partitions must have the same space (in MB)
		for (unsigned short i=0; i<num_of_partitions; i++)
			subcache_size[i] = (possible_lowest_repr_chunks / num_of_partitions)/
				content_distribution::get_repr_h()->get_storage_space_of_representation(i+1);

	} else 	if ( strcmp(equality, "number_of_objects")==0 ) 
	{	// All partitions must have the same number of objects
		float denominator = 0;
		for (unsigned short i=0; i<num_of_partitions; i++)
			denominator += content_distribution::get_repr_h()->get_storage_space_of_representation(i+1)/
				(float)content_distribution::get_repr_h()->get_storage_space_of_representation(num_of_partitions);

		for (unsigned short i=0; i<num_of_partitions; i++)
			subcache_size[i] = 	cache_slots / denominator;
	}else
		severe_error(__FILE__,__LINE__,"Equality parameter not recognized");

	for (unsigned short i=0; i<num_of_partitions; i++)
	{
	    subcaches[i] = new lru_cache();
	    subcaches[i]->initialize_(std::string("lce"), subcache_size[i] );
	}
	//} PARTITION SET UP

	if (cache_slots > 0)
		// Retrieve the proactive component
		proactive_component = (ProactiveComponent*) getParentModule()->getSubmodule("proactive_component");
	else
		proactive_component = NULL;
}

bool partitioned_cache::handle_data(ccn_data* data_msg, chunk_t& evicted, bool is_it_possible_to_cache)
{
	bool accept_new_chunk = base_cache::handle_data(data_msg, evicted, is_it_possible_to_cache);
	chunk_t chunk_id = data_msg->get_chunk_id();
	unsigned short incoming_repr = content_distribution::get_repr_h()->get_representation_number(chunk_id);
	#ifdef SEVERE_DEBUG
		check_if_correct();
		content_distribution::get_repr_h()->check_representation_mask(chunk_id, CCN_D);
		if (evicted != 0)
			severe_error(__FILE__,__LINE__,"Evicted should be 0 now");
	#endif

	if (accept_new_chunk)
	{
		cache_item_descriptor* old = data_lookup_receiving_data(chunk_id);

		if(	old != NULL &&
			content_distribution::get_repr_h()->get_representation_number(old->k) < incoming_repr
		){
			// There is a chunk with the same [object_id, chunk_num] but the incoming representation is
			// better. I will remove the old one and accept the new one.
            remove_from_cache(old);
            old = NULL; // To signal that the new chunk must be stored
		}

		if (old == NULL)
		{
			// No chunk with the same [object_id, chunk_num] is in cache
			#ifdef SEVERE_DEBUG
				unsigned occupied_before = 
					subcaches[incoming_repr-1]->get_occupied_slots();
			#endif

			accept_new_chunk = subcaches[incoming_repr-1]->handle_data(data_msg, evicted, accept_new_chunk);

		    #ifdef SEVERE_DEBUG
		    	if (occupied_before == 0 && evicted!=0)
					severe_error(__FILE__,__LINE__,"You evicted a ghost chunk");
			#endif

		    if (evicted != 0)
		    {
		    	chunk_t evicted_with_no_repr = evicted;
		    	__srepresentation_mask(evicted_with_no_repr, 0x0000);
		    	quality_map.erase(evicted_with_no_repr);
		    }
		} else
		{
			//There is already a chunk that can replace the incoming one
			accept_new_chunk = false;
		}

		if (accept_new_chunk)
		{
		    unsigned short incoming_representation =
		                    content_distribution::get_repr_h()->get_representation_number(chunk_id);
		    chunk_t chunk_id_without_repr = chunk_id;
		    __srepresentation_mask(chunk_id_without_repr, 0x0000);
		    quality_map[chunk_id_without_repr ] =incoming_representation;
		}
	}
	#ifdef SEVERE_DEBUG
		check_if_correct();
	#endif

	return accept_new_chunk;
}

cache_item_descriptor* partitioned_cache::data_lookup_receiving_interest(chunk_t requested_chunk_id)
{
	cache_item_descriptor* stored = NULL;
	chunk_t chunk_id_without_repr = requested_chunk_id;
	__srepresentation_mask(chunk_id_without_repr, 0x0000);
	unordered_map<chunk_t, unsigned short>::iterator it = quality_map.find(chunk_id_without_repr);

	if (it != quality_map.end() )
	{
		unsigned short stored_representation = it->second;
		stored = subcaches[stored_representation-1]->data_lookup_receiving_interest(requested_chunk_id);
		if ( content_distribution::get_repr_h()->is_it_compatible(stored->k, requested_chunk_id) )
			// A good chunk has been found
			proactive_component->try_to_improve(stored->k, requested_chunk_id);
		else
			// The stored representation does not match with the requested ones
			stored = NULL;
	}
	return stored;
}

cache_item_descriptor* partitioned_cache::data_lookup_receiving_data(chunk_t chunk_id)
{
	#ifdef SEVERE_ERROR
		check_if_correct();
	#endif

    cache_item_descriptor* good_already_stored_chunk;

    // Retrieve the current stored version of the chunk
    chunk_t chunk_id_without_repr = chunk_id;
    __srepresentation_mask(chunk_id_without_repr, 0x0000);
    unordered_map<chunk_t, unsigned short>::iterator it = quality_map.find(chunk_id_without_repr);

    if (it == quality_map.end() )
        // No chunk like the incoming one has been stored
        good_already_stored_chunk =  NULL;
    else{
        unsigned short old_representation = it->second;
    	good_already_stored_chunk =
    			subcaches[old_representation-1]->data_lookup_receiving_data(chunk_id);
		#ifdef SEVERE_DEBUG
			if (good_already_stored_chunk ==NULL)
			{
				std::stringstream ermsg;
				ermsg<<"quality_map said that a good chunk was stored in the cache partition of level "
						<<old_representation<<" but looking into it I get a NULL pointer. This is an "
						<<"error";
				severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
			}
		#endif

    }
    return good_already_stored_chunk;
}

void partitioned_cache::remove_from_cache(cache_item_descriptor* descr)
{
    chunk_t chunk_id = descr->k;
    unsigned short representation=content_distribution::get_repr_h()->get_representation_number(chunk_id);

	// All chunks must be indexed only based on object_id, chunk_number
	__srepresentation_mask(chunk_id, 0x0000);

	#ifdef SEVERE_DEBUG
		check_if_correct();
	#endif
 	subcaches[representation-1]->remove_from_cache(descr);

 	quality_map.erase(chunk_id);
}


// Return true only if all the subcaches are full
bool partitioned_cache::full()
{
    for (unsigned short i=0; i<num_of_partitions; i++)
        if (subcaches[i]!=NULL && !subcaches[i]->full() )
            return false;
    return true;
}

void partitioned_cache::finish()
{
	base_cache::finish();

	unsigned short num_of_repr = content_distribution::get_repr_h()->get_num_of_representations();

	std::stringstream breakdown_str;
	for (unsigned i = 0; i < num_of_repr; i++)
	{
	    std::stringstream tmp;
	    if ( subcaches[i] == NULL )
	        tmp << "_";
	    else
	        tmp<<subcaches[i]->get_occupied_slots();
		breakdown_str <<tmp<<":";
	}

    char name [150];
    sprintf ( name, "representation_breakdown[%d] %s", getIndex(), breakdown_str.str().c_str());
    recordScalar (name, 0);
}


#ifdef SEVERE_DEBUG
void partitioned_cache::check_if_correct()
{
	base_cache::check_if_correct();
	unsigned stored_chunks = 0;

	for (unsigned short i=0; i<num_of_partitions; i++)
	{
	    if (subcaches[i]!= NULL)
	    {
	        // subcache is active
            subcaches[i]->check_if_correct();
            stored_chunks += subcaches[i]->get_occupied_slots();
	    }
	}

	//{ CHECK quality_map CONSISTENCY
	if (stored_chunks != quality_map.size() )
	{
		std::stringstream ermsg;
		ermsg<<"stored_chunks="<<stored_chunks<<" while quality_map.size()="<<quality_map.size()<<
				"; cache dump = "<< dump();
		severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
	}

	for(unordered_map<chunk_t, unsigned short>::iterator it = quality_map.begin(); it != quality_map.end(); it++)
	{
		chunk_t chunk_id_with_no_repr = it->first;
		if (__representation_mask(chunk_id_with_no_repr ) != 0x0000 )
			severe_error(__FILE__,__LINE__,"All objects must be indexed in a representation unaware fashon in the quality map");

		unsigned short representation = it->second;

		if ( !subcaches[representation-1]->fake_lookup(chunk_id_with_no_repr) )
			severe_error(__FILE__,__LINE__,"Inconsistency of quality_map");
	}
	//} CHECK quality_map CONSISTENCY
}

const char* partitioned_cache::dump()
{
	std::stringstream str;
	for (unsigned short i=0; i<num_of_partitions; i++)
	{
		if (subcaches[i]==NULL) 
		{
			subcaches[i]->dump();
		}
	}
	return "ciao";
}

void partitioned_cache::check_representation_compatibility(){}
#endif

//</aa
