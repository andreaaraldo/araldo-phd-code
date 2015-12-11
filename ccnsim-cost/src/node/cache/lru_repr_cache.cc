//<aa>
#include "lru_repr_cache.h"
#include "content_distribution.h"
Register_Class(lru_repr_cache);

void lru_repr_cache::initialize()
{
	base_cache::initialize();

	if (get_slots() > 0)
		// Retrieve the proactive component
		proactive_component = (ProactiveComponent*) 
				getParentModule()->getSubmodule("proactive_component");
	else
		proactive_component = NULL;

}

void lru_repr_cache::initialize_cache_slots(unsigned chunks_at_highest_representation)
{
    unsigned highest_representation_space =
    		content_distribution::get_repr_h()->get_storage_space_of_representation(
    				content_distribution::get_repr_h()->get_num_of_representations() );
	cache_slots = (unsigned) chunks_at_highest_representation * highest_representation_space;
}

cache_item_descriptor* lru_repr_cache::data_lookup_receiving_interest(chunk_t requested_chunk_id)
{
	cache_item_descriptor* stored = lru_cache::data_lookup_receiving_interest(requested_chunk_id);
	if (stored != NULL)
	{
		if ( content_distribution::get_repr_h()->is_it_compatible(stored->k, requested_chunk_id) )
			// A good chunk has been found
			proactive_component->try_to_improve(stored->k, requested_chunk_id);
		else
			// The stored representation does not match with the requested ones
			stored = NULL;
	}
	return stored;
}


cache_item_descriptor* lru_repr_cache::data_lookup_receiving_data(chunk_t incoming_chunk_id)
{
	cache_item_descriptor* stored = lru_cache::data_lookup_receiving_data(incoming_chunk_id);
	if (stored != NULL)
	{
		// There is a chunk with the same [object_id, chunk_num] stored in the cache.
		// It has already been put at the head of the position list
		chunk_t old_chunk_id = stored->k;
		representation_mask_t incoming_mask = __representation_mask(incoming_chunk_id);
		representation_mask_t stored_mask = __representation_mask(old_chunk_id);
		if (stored_mask < incoming_mask )
		{	// The incoming representation is better than the stored one.
			remove_from_cache(stored);
			stored = NULL; // To signal that the new chunk must be stored
		}
	}
	#ifdef SEVERE_DEBUG
	check_if_correct();
	#endif
	return stored;
}

void lru_repr_cache::finish()
{
	lru_cache::finish();

	//{ COMPUTE REPRESENTATION BREAKDOWN
	unsigned short num_of_repr = content_distribution::get_repr_h()->get_num_of_representations();
	unsigned* breakdown = (unsigned*)calloc(content_distribution::get_repr_h()->get_num_of_representations(), sizeof(unsigned) );
	unordered_map<chunk_t,cache_item_descriptor *>::const_iterator it;
	for ( it = beginning_of_cache(); it != end_of_cache(); ++it )
	{
		chunk_t chunk_id = it->second->k;
	    breakdown[content_distribution::get_repr_h()->get_representation_number(chunk_id)-1]++;
	}

	std::stringstream breakdown_str;
	for (unsigned i = 0; i < num_of_repr; i++)
		breakdown_str << breakdown[i]<<":";
    char name [60];
    sprintf ( name, "representation_breakdown[%d] %s", getIndex(), breakdown_str.str().c_str());
    recordScalar (name, 0);
	//} COMPUTE REPRESENTATION BREAKDOWN

}

chunk_t lru_repr_cache::shrink()
{
	chunk_t evicted=0;
	while (get_occupied_slots()  > get_slots() )
	{
		evicted = lru_->k;
		//if the cache is full, delete the last element
		remove_from_cache(lru_);
	}

	#ifdef SEVERE_DEBUG
		if (evicted != 0)
			content_distribution::get_repr_h()->check_representation_mask(evicted, CCN_D);
		check_if_correct();
	#endif

	return evicted;
}

void lru_repr_cache::update_occupied_slots(chunk_t chunk_id, operation op)
{
    unsigned storage_space = content_distribution::get_repr_h()->get_storage_space_of_chunk(chunk_id);
    int increment = (op == insertion)? storage_space : -1*storage_space;
    occupied_slots += increment;
}


#ifdef SEVERE_DEBUG
void lru_repr_cache::check_representation_compatibility(){}

void lru_repr_cache::check_if_correct()
{
	lru_cache::check_if_correct();
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
		occupied_slots_tmp += breakdown[i] * content_distribution::get_repr_h()->get_storage_space_of_representation(i+1);
	if (occupied_slots_tmp != occupied_slots || occupied_slots > get_slots() )
	{
		std::stringstream ermsg;
		ermsg<<"error in the computation of the occupied slots. occupied_slots_tmp="<<occupied_slots_tmp<<
			"; occupied_slots="<<occupied_slots <<"; get_slots()="<<get_slots()<<"; breakdown_str="<<
			breakdown_str.str()<< "; content_str="<<get_cache_content("", "; ") << 
			"; requested storage per repr="<<
			content_distribution::get_repr_h()->dump_storage()<<"; bitrates="<<
			content_distribution::get_repr_h()->dump_storage();
		severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
	}
	free(breakdown);
}

#endif
//</aa
