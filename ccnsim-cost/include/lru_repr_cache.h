/*
 * ccnSim is a scalable chunk-level simulator for Content Centric
 * Networks (CCN), that we developed in the context of ANR Connect
 * (http://www.anr-connect.org/)
 *
 * People:
 *    Giuseppe Rossini (lead developer, mailto giuseppe.rossini@enst.fr)
 *	  Andrea Araldo (mailto andrea.araldo@gmail.com)
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

#ifndef LRU_REPR_CACHE_H_
#define LRU_REPR_CACHE_H_

#include <boost/unordered_map.hpp>
#include "lru_cache.h"
#include "ccnsim.h"
#include "error_handling.h"
#include "statistics.h"
#include "client.h"
#include "ProactiveComponent.h"



using namespace std;
using namespace boost;

class lru_repr_cache:public lru_cache
{ 
	public:
		lru_repr_cache():lru_cache(){;}


		#ifdef SEVERE_DEBUG
			virtual void check_if_correct();
		#endif


    protected:
		ProactiveComponent* proactive_component;
		virtual void initialize_cache_slots(unsigned chunks_at_highest_representation);
		virtual void update_occupied_slots(chunk_t chunk_id, operation op);
		virtual void initialize();
		virtual cache_item_descriptor* data_lookup_receiving_data(chunk_t incoming_chunk_id);
		virtual cache_item_descriptor* data_lookup_receiving_interest(chunk_t requested_chunk_id);
		virtual void finish();
		virtual chunk_t shrink();	// Set the cache to the right size and returns the evicted
									// chunk id
		#ifdef SEVERE_DEBUG
			virtual void check_representation_compatibility();
		#endif
};
#endif
