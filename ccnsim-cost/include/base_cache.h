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
#ifndef B_CACHE_H_
#define B_CACHE_H_


#include "ccnsim.h"
//<aa>
#include "error_handling.h"
#include "content_distribution.h"
#include "statistics.h"
#include "ccn_data.h"
enum operation {insertion, removal};
//</aa>
class DecisionPolicy;


// Indicate the position within the cache. It is useful with policies like lru. You can ignore it when you
// you use policies that do not require any ordering.
// In order to look-up for an
// element it just suffices removing the element from the current position and
// inserting it within the head of the list
struct cache_item_descriptor
{
	cache_item_descriptor(); // Initialize the price as undefined
	cache_item_descriptor(chunk_t chunk_id); // Initialize the price as undefined
	cache_item_descriptor(chunk_t chunk_id, double price);

    //older and newer track the lru_position within the 
    //lru cache
    cache_item_descriptor* older;
    cache_item_descriptor* newer;
    chunk_t k; //identifier of the chunk, i.e. [object_id, chunk_number, representation_mask]
    simtime_t hit_time;
	//<aa>
	// double cost;	// now called price
	double price_;   //meaningful only with cost aware caching. In previous versions 
					//of ccnsim it was called cost

	double get_price(){
		#ifdef SEVERE_DEBUG
		if ( statistics::record_cache_value && price_ <0 )
		{
			std::stringstream ermsg; 
			ermsg<<"price is "<< price_ <<", i.e. it is not correctly initialized.";
			severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
		}
		#endif

		return price_; 
	}

	void set_price(double new_price) 
	{
		price_ = new_price;
		#ifdef SEVERE_DEBUG
		if ( statistics::record_cache_value && price_ < 0 )
		{
			std::stringstream ermsg; 
			ermsg<<"price=="<< price_ <<", new_price=="<<new_price<<", i.e. it is not initialized.";
			severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
		}
		#endif
	}
	//</aa>
};




//Base cache class: it implements the basic behaviour of every cache by the mean of two abstract functions:
//
//-) handle_data: stores chunks within the cache with a given policy
//
struct cache_stat_entry{
    unsigned int  miss; //Total number of misses
    unsigned int  hit; //Totatle number of hit
    cache_stat_entry():miss(0),hit(0){;}
    double rate(){ return hit *1./(hit+miss);} //return the miss rate of the class
};

class base_cache : public abstract_node
{
    friend class statistics;

    protected:
		//<aa> I replaced cache_size with cache_slots </aa>
		unsigned cache_slots;// <aa> A cache slot is the elementary unit of cache space. A chunk can occupy
							 // one or more cache slots, depending on its representation level </aa>
    	uint32_t occupied_slots; //actual size of the cache
		virtual void initialize();
		virtual void initialize_cache_slots(unsigned cache_slots);
		void handleMessage (cMessage *){;}
		virtual void finish();

		virtual const char* dump();
		virtual cache_item_descriptor* data_lookup(chunk_t) const;

		//<aa>
		#ifdef SEVERE_DEBUG
			virtual void check_representation_compatibility();
			bool initialized;
		#endif

		virtual void insert_into_cache(cache_item_descriptor* descr);
		virtual void update_occupied_slots(chunk_t chunk_id, operation op);
		virtual cache_item_descriptor* find_in_cache(chunk_t chunk_id) const; //NULL if not found
		virtual unordered_map<chunk_t,cache_item_descriptor *>::const_iterator end_of_cache() const;
		virtual unordered_map<chunk_t,cache_item_descriptor *>::const_iterator beginning_of_cache() const;

		char dump_filename[500]; // Cache content will be dumped here
		//</aa>
	
    public:

		virtual void remove_from_cache(cache_item_descriptor* descr);

		//Inteface function (depending by internal data structures of each cache)
		// Decides whether to store the new chunk. If stored, it evicts some stored chunks, if
		// needed, and returns the last evicted one
		virtual bool handle_data(ccn_data*, chunk_t& last_evicted_chunk,
		            bool is_it_possible_to_cache) = 0;

		//Outside function behaviour
		int get_size(); //deprecated

		//<aa>
		virtual void after_handle_data(bool was_data_accepted);
		virtual void initialize_(std::string decision_policy, unsigned cache_slots);
		unsigned  get_slots() { return cache_slots; }
		void set_slots(unsigned);
		virtual cache_item_descriptor* data_lookup_receiving_data (chunk_t incoming_chunk_id);
		virtual cache_item_descriptor* data_lookup_receiving_interest (chunk_t requested_chunk_id);
		//</aa>

		void set_size(uint32_t);

		const virtual bool fake_lookup(chunk_t) const; // Look for the chunk without internal modifications
		cache_item_descriptor* handle_interest(chunk_t);

		// Lookup without hit/miss statistics (used with the 2-LRU meta-caching strategy to lookup the name cache)
		bool lookup_name(chunk_t);
		void store (cMessage *); //deprecated

		void store_name(chunk_t);    // Store the content ID inside the name cache (only with 2-LRU meta-caching).

		void clear_stat();

		//<aa>.
		virtual void after_sending_data(ccn_data* data_msg);
		virtual uint32_t get_decision_yes();
		virtual uint32_t get_decision_no();
		virtual void set_decision_yes(uint32_t n);
		virtual void set_decision_no(uint32_t n);
		virtual const DecisionPolicy* get_decisor();
		virtual bool full();
		virtual unsigned get_occupied_slots();


		virtual double get_cache_value();
		virtual double get_average_price();

		#ifdef SEVERE_DEBUG
			virtual bool is_initialized();
			base_cache():abstract_node(){initialized=false; occupied_slots=0;};
			virtual void check_if_correct();
			virtual const char* get_cache_content();
		#endif
		//</aa>

		//{ DEPRECATED
		bool lookup(chunk_t);
		virtual bool data_store(ccn_data*);
		//} DEPRECATED

    private:

		int name_cache_size;   		// Size of the name cache expressed in number of content IDs (only with 2-LRU meta-caching).

		DecisionPolicy *decisor;

		//Average statistics
		uint32_t miss;
		uint32_t hit;

		//<aa>
		uint32_t decision_yes;
		uint32_t decision_no;
		//</aa>


		//Per file statistics
		cache_stat_entry *cache_stats;

		unordered_map<chunk_t, cache_item_descriptor*> cache;

};

#endif
