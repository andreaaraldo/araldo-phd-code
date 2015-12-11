/*
 * ccnSim is a scalable chunk-level simulator for Content Centric
 * Networks (CCN), that we developed in the context of ANR Connect
 * (http://www.anr-connect.org/)
 *
 * People:
 *    Giuseppe Rossini (lead developer, mailto giuseppe.rossini@enst.fr)
 *    Raffaele Chiocchetti (developer, mailto raffaele.chiocchetti@gmail.com)
 *    Dario Rossi (occasional debugger, mailto dario.rossi@enst.fr)
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 * 
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#include <iostream>
#include "lru_cache.h"

//<aa>
#include <stdexcept>
#include "ccnsim.h"
#include "error_handling.h"
#include "costaware_ancestor_policy.h"
#include "statistics.h"
//</aa>

Register_Class(lru_cache);

//<aa>
void lru_cache::initialize()
{
	base_cache::initialize();
	#ifdef SEVERE_DEBUG
		if( content_distribution::get_repr_h()->get_num_of_representations() != 1 )
		{
			std::stringstream ermsg; 
			ermsg<<"This cache policy is intended to work only with one representation for each chunk."<<
				" Slight modifications may be required in order to handle more than one representation.";
			severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
		}
	#endif
}

bool lru_cache::is_it_empty() const
{
	//{ CHECK
		#ifdef SEVERE_DEBUG
		if ( (lru_==NULL && mru_!=NULL ) || (lru_!=NULL && mru_==NULL ) )
		{
			std::stringstream ermsg; 
			ermsg<<"Error in pointer updarte";
			severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
		}
		#endif
	// }CHECK

	if (lru_==NULL)
		return true;
	else return false;
}
//</aa>

// Removes last element if needed and returns its chunk_id
chunk_t lru_cache::shrink()
{
		chunk_t evicted = 0;
		if (get_occupied_slots()  > get_slots() )
		{
			evicted = lru_->k;
		    //if the cache is full, delete the last element
			remove_from_cache(lru_);
		}

		#ifdef SEVERE_DEBUG
			if (evicted !=0 )
				content_distribution::get_repr_h()->check_representation_mask(evicted,CCN_D);
			check_if_correct();
		#endif
		return evicted;
}

//<aa>
void lru_cache::remove_from_cache(chunk_t chunk_id, unsigned storage_space)
{
	severe_error(__FILE__,__LINE__,"remove_from_cache(chunk_t, unsigned) cannot be called on lru_cache. Use remove_from_cache(cache_item_descriptor*) instead.");
}

void lru_cache::insert_into_cache(cache_item_descriptor* p)
{
	// {DESCRIPTOR UPDATE
	p->hit_time = simTime();
	p->newer = 0;
	p->older = 0;

	// The cache is empty. Add just one element if it fits into the cache space. 
	// The mru and lru element are the same
	if ( is_it_empty() )
	{
		lru_ = p;
		mru_ = p;
	}else{
		//The cache is not empty. The new element is the newest. Add it in the front
		//of the list
		p->older = mru_; // mru swaps in second position (in terms of utilization rank)
		mru_->newer = p; // update the newer element for the secon newest element
		mru_ = p; //update the mru (which becomes that just inserted)
	}
	// }DESCRIPTOR UPDATE
	base_cache::insert_into_cache(p); 
}

void lru_cache::remove_from_cache(cache_item_descriptor* descr)
{
	#ifdef SEVERE_DEBUG
		if(get_occupied_slots()==0 )
			severe_error(__FILE__,__LINE__,"Trying to remove a chunk from an empty cache");
	#endif
	cache_item_descriptor* newer = descr->newer;
	cache_item_descriptor* older = descr->older;

	if (older!=NULL)
	{	// the evicted object was not the lru. Therefore exists an older object
		// that we must update
		older->newer = newer;
	}

	if (newer!=NULL)
	{	// the evicted object was not the mru. Therefore exists a newer object
		// that we must update
		newer->older = older;
	}

	if (older == NULL)
		lru_=newer;
	if (newer == NULL)
		mru_=older;

	base_cache::remove_from_cache(descr);
    free(descr);
}
//</aa>

// Decides whether to store the new chunk. If storing, evicts lru object if needed
bool lru_cache::handle_data(ccn_data* data_msg, chunk_t& last_evicted_chunk,
        bool is_it_possible_to_cache)
{
	bool accept_new_chunk = base_cache::handle_data(data_msg, last_evicted_chunk,
	        is_it_possible_to_cache);
	chunk_t chunk_id = data_msg->get_chunk_id();

	#ifdef SEVERE_DEBUG
		unsigned occupied_before = get_occupied_slots();
		check_if_correct();
		content_distribution::get_repr_h()->check_representation_mask(chunk_id, CCN_D);

		if (last_evicted_chunk != 0)
					content_distribution::get_repr_h()->check_representation_mask(
							last_evicted_chunk, CCN_D);
		unsigned occupied_after_insertion;
	#endif

	if (accept_new_chunk)
	{
		cache_item_descriptor* old = data_lookup_receiving_data(chunk_id);
		if (old == NULL)
		{
			// There is no chunk already stored that can replace the incoming one.
			// We need to store the incoming one.
			insert_into_cache(new cache_item_descriptor(chunk_id, data_msg->getPrice() )  );

			#ifdef SEVERE_DEBUG
				occupied_after_insertion = get_occupied_slots();
			#endif

			last_evicted_chunk = shrink();
		} else 
		{
			//There is already a chunk that can replace the incoming one
			accept_new_chunk = false;
		}
	}

	#ifdef SEVERE_DEBUG
		if (last_evicted_chunk != 0)
			content_distribution::get_repr_h()->check_representation_mask(
					last_evicted_chunk, CCN_D);

		if (last_evicted_chunk == chunk_id)
		{
			std::stringstream ermsg;
			ermsg<<"Incoming chunk "<<__id(chunk_id)<<":"<<__chunk(chunk_id)<<":"<<
				__representation_mask(chunk_id)<<". Immediately after you cached it, you "<<
				"evicted it. This is weird. Occupation before : after_insertion : after_shrink "<<
				occupied_before<<" : "<< occupied_after_insertion <<" : "<< get_occupied_slots();
			severe_error(__FILE__,__LINE__,ermsg.str().c_str());
		}

		if (occupied_before == 0 && last_evicted_chunk != 0)
		{
			std::stringstream ermsg;
			ermsg<<"Incoming chunk "<<__id(chunk_id)<<":"<<__chunk(chunk_id)<<":"<<
					__representation_mask(chunk_id)<<"; evicted_chunk:"<<
					__id(last_evicted_chunk)<<":"<<__chunk(last_evicted_chunk)<<":"<<
					__representation_mask(last_evicted_chunk)<<" while it should be 0,"<<
					"given that before the reception of the incoming chunk, cache was empty";
			severe_error(__FILE__,__LINE__,ermsg.str().c_str());
		}
	#endif

	return accept_new_chunk;
}

//<aa>
cache_item_descriptor* lru_cache::get_mru(){
	return mru_;
}

cache_item_descriptor* lru_cache::get_lru(){
	#ifdef SEVERE_DEBUG
	if (statistics::record_cache_value ){
		lru_->get_price(); // to verify whether the price is correctly set up
	}
	#endif

	return lru_;
}

void lru_cache::set_lru(cache_item_descriptor* new_lru)
{
	lru_ = new_lru;
}

void lru_cache::set_mru(cache_item_descriptor* new_mru)
{
	mru_ = new_mru;
}


const cache_item_descriptor* lru_cache::get_eviction_candidate(){
	if ( full() ) 
		return get_lru();
	else return NULL;
}

//</aa>

const bool lru_cache::fake_lookup(chunk_t chunk_id) const
{
	#ifdef SEVERE_DEBUG
		if (__representation_mask(chunk_id) != 0x0000 )
		{
			std::stringstream ermsg; 
			ermsg<<"The identifier of the object you want to erase must be representation-agnostic, "<<
				"i.e. representation_mask should be zero";
			severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
		}
	#endif

    cache_item_descriptor* cached = find_in_cache(chunk_id);
    //look for the elements
    if (cached)
    {
		return true;
    }else
		//if not found return false and do nothing
		return true;
}

// Returns the pointer to the cache item descritor or NULL if no item is found
cache_item_descriptor* lru_cache::data_lookup(chunk_t chunk_id)
{
	cache_item_descriptor* pos_elem = base_cache::data_lookup(chunk_id);

    if (pos_elem == NULL)
	{
		// No chunk with the same [object_id, chunk_num] has been found
		return NULL;
    }else{
		// A chunk with the same [object_id, chunk_num] has been found. I put it at the head of
		// the list
		//{ UPDATE DESCRIPTOR
			// If content matched, update the position
			if (pos_elem->older && pos_elem->newer)
			{
				//if the element is in the middle remove the element from the list
				pos_elem->newer->older = pos_elem->older;
				pos_elem->older->newer = pos_elem->newer;
			}else if (!pos_elem->newer){
				//if the element is the mru
				return pos_elem; //do nothing, return true
			} else{
				//if the element is the lru, remove the element from the bottom of the list
				set_lru(pos_elem->newer);
				get_lru()->older = 0;
			}

			//Place the elements in front of the position list (it's the newest one)
			pos_elem->older = get_mru();
			pos_elem->newer = 0;
			get_mru()->newer = pos_elem;

			//update the mru
			set_mru(pos_elem);
			get_mru()->hit_time = simTime();
		//} UPDATE DESCRIPTOR
		return pos_elem;
	}
}

const char* lru_cache::get_cache_content(const char* line_initiator, const char* separator)
{
	std::stringstream content_str;
	cache_item_descriptor *it = get_mru();
    while (it)
	{
		content_str<< line_initiator<<":"<<__id(it->k)<<":"<<
				__chunk(it->k)<<":"<<__representation_mask(it->k)<<	separator;
		it = it->older;
    }
	return content_str.str().c_str();
}

const char* lru_cache::dump()
{
	ofstream out_f; out_f.open (dump_filename, std::ofstream::out | std::ofstream::app);
	out_f<<get_cache_content(SIMTIME_STR(simTime())  ,"\n")<<endl;
	out_f.close();
	return "ciao";
}

//<aa>
// {STATISTICS
	double lru_cache::get_cache_value()
	{
		#ifdef SEVERE_DEBUG	
		if ( !statistics::record_cache_value )
		{
				std::stringstream ermsg; 
				ermsg<<"get_cache_value(..) is useful when you want to record "<<
					" the cache_value; when statistics::record_cache_value is disabled this method "<<
					" may be useless. Make sure you really need this method. If yes, disable this"<<
					" error.If not, try to rethink your code";
				severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
		}
		#endif

		double value = 0;

		WeightedContentDistribution* content_distribution_module = 
			Costaware_ancestor::get_weighted_content_distribution_module();

		cache_item_descriptor *it = get_mru();
		int p = 1;
		while (it){
			chunk_t object_index = it->k;
			double alpha = content_distribution_module->get_alpha();
			double price = it->get_price();
			double weight = Costaware_ancestor::compute_content_weight(object_index,price,alpha);
			value += weight;
		
	//		cout<< p <<" ] "<< object_index <<" : "<< price << " : "<< weight << endl;
			p++;
			it = it->older;
		}

		return value;
	}

	double lru_cache::get_average_price()
	{
		#ifdef SEVERE_DEBUG	
		if ( !statistics::record_cache_value )
		{
				std::stringstream ermsg; 
				ermsg<<"get_average_price(..) is useful when you want to record "<<
					" the cache_value; when statistics::record_cache_value is disabled this method "<<
					" may be useless. Make sure you really need this method. If yes, disable this"<<
					" error.If not, try to rethink your code";
				severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
		}
		#endif

		double sum_of_prices = 0;

		cache_item_descriptor *it = get_mru();
		int counter = 0;
		while (it){
			double price = it->get_price();
			sum_of_prices += price;
			it = it->older;
			counter++;
		}

		double average_price = sum_of_prices / counter;
		return average_price;
	}
	//</aa>
// }STATISTICS

#ifdef SEVERE_DEBUG
void lru_cache::check_if_correct()
{
	base_cache::check_if_correct();
	unordered_map<chunk_t, unsigned> cache_counter; //counts how many representations are stored per
													// each chunk
	cache_item_descriptor *newer = NULL;
	cache_item_descriptor *it = get_mru();
    while (it)
	{
    	if(it->newer != newer)
    		severe_error(__FILE__,__LINE__,"Error in pointers" );

		chunk_t chunk_id = it->k;
		__srepresentation_mask(chunk_id, 0x0000);
		cache_counter[chunk_id]++;
		if (cache_counter[chunk_id]>1)
		{
			std::stringstream ermsg; 
			ermsg<<"The chunk "<<__id(chunk_id)<<":"<<__chunk(chunk_id)<<" has been stored more than once"
				<<". Cache content is "<<get_cache_content("","; ");
			severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
		}
		newer = it;
		it = it->older;
    }
}
#endif
