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
#include "fifo_cache.h"
#include "error_handling.h"
#include "content_distribution.h"

Register_Class(fifo_cache);

bool fifo_cache::handle_data(ccn_data* data_msg, chunk_t& evicted, bool is_it_possible_to_cache)
{
	bool return_value = true;
	base_cache::handle_data(data_msg, evicted, is_it_possible_to_cache);
	chunk_t chunk = data_msg->get_chunk_id();
	#ifdef SEVERE_DEBUG
	if( content_distribution::get_repr_h()->get_num_of_representations() != 1 )
	{
		std::stringstream ermsg; 
		ermsg<<"This cache policy is intended to work only with one representation for each chunk."<<
			" Slight modifications may be required in order to handle more than one representation.";
		severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
	}
	#endif

   insert_into_cache(new cache_item_descriptor(chunk) );
   deq.push_back(chunk);

   if ( get_occupied_slots() > (unsigned)get_size() ) {
   //Eviction of the last element
       evicted = deq.front();
       deq.pop_front();
       remove_from_cache( new cache_item_descriptor(evicted) );
   }
	return return_value;
}



