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
#include "random_cache.h"
#include "content_distribution.h"

#include "error_handling.h"
Register_Class (random_cache);



void random_cache::initialize(){
    base_cache::initialize();
}

bool random_cache::handle_data(ccn_data* data_msg, chunk_t& evicted, bool is_it_possible_to_cache)
{
	bool return_value= base_cache::handle_data(data_msg, evicted,is_it_possible_to_cache);
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

	insert_into_cache( new cache_item_descriptor(chunk) );
    if ( get_occupied_slots() == get_slots() ){
        //Replacing a random element
        unsigned int pos = intrand(  deq.size() );
        chunk_t evicted = deq.at(pos);

        deq.at(pos) = chunk;
        remove_from_cache( new cache_item_descriptor(evicted) );

    } else
        deq.push_back(chunk);

	return return_value;
}



/*Deprecated: used in order to fill up caches with random chunks*/
bool random_cache::warmup(){
    int C = get_size();
    int k = getIndex();
    uint64_t chunk=0;

    cout<<"Starting warmup..."<<endl;
    for (int i = k*C+1; i<=(k+1)*C; i++)
	{
		__sid(chunk,i);
		insert_into_cache( new cache_item_descriptor(chunk) );
		//cout<<"cache index "<<k<<" storing "<<i<<endl;
		//deq.push_back(chunk);
    }

    //vector<file> &catalog = content_distribution::catalog;
    //uint32_t s=0, 
    //         i=1,
    //         F = catalog.size() - 1;
    //uint64_t chunk;
    //file file;

    ////Size represents the chache size expressed in chunks
    //cout<<"Starting warmup..."<<endl;

    //chunk = 0;
    //while (s < get_size() && i <= F){
    //    __sid(chunk,i);
    //    cache[chunk] = true;
    //    deq.push_back(chunk);
    //    i++;
    //    s++;
    //}

    ////Return if the cache has been filled or not
    //if (i>F)
    //    return false;

    cout<<"[OK] Cache full"<<endl;
    return true;



}
