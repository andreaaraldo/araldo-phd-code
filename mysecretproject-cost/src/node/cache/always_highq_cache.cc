//<aa>
#include "always_highq_cache.h"
#include "ccnsim.h"

Register_Class(always_highq_cache);

void always_highq_cache::initialize()
{
	base_cache::initialize();

	if (cache_slots > 0)
		// Retrieve the proactive component
		proactive_component = (ProactiveComponent*) getParentModule()->getSubmodule("proactive_component");
	else
		proactive_component = NULL;
}

bool always_highq_cache::handle_data(ccn_data* data_msg, chunk_t& evicted,
        bool is_it_possible_to_cache)
{
	bool accept_new_chunk = is_it_possible_to_cache;
    if (accept_new_chunk)
    {
		chunk_t chunk_id = data_msg->get_chunk_id();
		unsigned short incoming_repr = content_distribution::get_repr_h()->get_representation_number(chunk_id);

		// I can cache the chunkn only if it is at the highest representation
		accept_new_chunk =
				( incoming_repr == content_distribution::get_repr_h()->get_num_of_representations() )
		    &&
		        lru_cache::handle_data(data_msg, evicted, accept_new_chunk);
    }

	#ifdef SEVERE_DEBUG
		check_if_correct();
		content_distribution::get_repr_h()->check_representation_mask(data_msg->get_chunk_id(), CCN_D);
	#endif
	return accept_new_chunk;
}

cache_item_descriptor* always_highq_cache::data_lookup_receiving_interest(chunk_t requested_chunk_id)
{
    cache_item_descriptor* stored = lru_cache::data_lookup_receiving_interest(requested_chunk_id);
	if (stored==NULL && cache_slots>0)
	{
		// No chunk has been found. I retrieve it at the highest representation, but only if I have
	    // some cache slots where to store it
	}
	#ifdef SEVERE_DEBUG
	else if (stored!=NULL)
	{
		unsigned short num_of_representations =
		            content_distribution::get_repr_h()->get_num_of_representations();
		if (	content_distribution::get_repr_h()->get_representation_number(stored->k) !=
	            num_of_representations
	    )
	        severe_error(__FILE__,__LINE__,"Found a chunk that is not at the highest representation");

	    if ( !content_distribution::get_repr_h()->is_it_compatible(stored->k, requested_chunk_id) )
	    				severe_error(__FILE__,__LINE__,"Found a stored object that is not compatible.");
	}
	#endif

	return stored;
}

void always_highq_cache::after_sending_data(ccn_data* data_msg)
{
	if (cache_slots>0)
	{
		unsigned short num_of_representations =
				content_distribution::get_repr_h()->get_num_of_representations();
		representation_mask_t max_mask = 0x0001 << (num_of_representations-1);
		chunk_t chunk_id = data_msg->getChunk();
		if ( (max_mask & __representation_mask(chunk_id) ) == 0 )
			// The data that we were able to provide was not the maximum. I try to retrieve the
			// maximum representation
			proactive_component->proactively_catch_a_chunk(__id(chunk_id), __chunk(chunk_id),
									0x0001 << (num_of_representations-1) );
	}
}

#ifdef SEVERE_DEBUG
void always_highq_cache::check_representation_compatibility(){}

void always_highq_cache::check_if_correct()
{
	lru_cache::check_if_correct();

	if (cache_slots == 0 && proactive_component != NULL)
	    severe_error(__FILE__,__LINE__, "No cache space and proactive component is active. This is impossible");

	unsigned num_of_repr = content_distribution::get_repr_h()->get_num_of_representations();
	unsigned* breakdown = (unsigned*)calloc(num_of_repr, sizeof(unsigned) );
	unordered_map<chunk_t,cache_item_descriptor *>::const_iterator it;
	for ( it = beginning_of_cache(); it != end_of_cache(); ++it )
	{
		chunk_t chunk_id = it->second->k;
	    breakdown[content_distribution::get_repr_h()->get_representation_number(chunk_id)-1]++;
	}

	std::stringstream breakdown_str;
	for (unsigned i = 0; i < num_of_repr; i++)
		breakdown_str << breakdown[i]<<":";


	unsigned occupied_slots_tmp = 0;
	for (unsigned i = 0; i < num_of_repr; i++)
		occupied_slots_tmp += breakdown[i];
	if (occupied_slots_tmp != occupied_slots || occupied_slots > get_slots() )
	{
		std::stringstream ermsg;
		ermsg<<"error in the computation of the occupied slots. occupied_slots_tmp="<<occupied_slots_tmp<<
			"; occupied_slots="<<occupied_slots <<"; get_slots()="<<get_slots()<<"; breakdown_str="<<
			breakdown_str.str()<< "; content_str="<<get_cache_content("", "; ") << "; requested storage per repr="<<
			content_distribution::get_repr_h()->dump_storage()<<"; bitrates="<<
			content_distribution::get_repr_h()->dump_storage();
		severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
	}
	free(breakdown);
}
#endif
//</aa
