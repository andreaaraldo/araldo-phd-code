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
//<aa>
#include "content_distribution.h"
#include "statistics.h"
#include "ccn_interest.h"
#include "ccn_data.h"
#include "ccnsim.h"
#include "client.h"
#include "error_handling.h"
#include "PIT.h"

PIT::PIT(double RTT_){ RTT=RTT_;}

// Returns true if an entry for the requested chunk was already in the pit. false otherwise
bool PIT::handle_interest(ccn_interest *int_msg, bool cacheable)
{
	bool previously_found;
	chunk_t request_chunk_id = int_msg->getChunk();
	chunk_t chunk_id_without_representation = request_chunk_id;
	__srepresentation_mask(chunk_id_without_representation, 0x0000);
	unordered_map < chunk_t , pit_entry >::iterator it = table.find(chunk_id_without_representation);

	if (
		   it == table.end() // No PIT entry was found
		|| int_msg->getNfound() // A timer expired in a client
		|| simTime() - it->second.time > 2*RTT
	){
    	if (it!=table.end())
		{
			table.erase(chunk_id_without_representation);
		}
    	table[chunk_id_without_representation].time = simTime();
    	if(!cacheable)						// Set the cacheable flag inside the PIT entry.
    		table[chunk_id_without_representation].cacheable.reset();
    	else
    		table[chunk_id_without_representation].cacheable.set();

		previously_found = false;
	}
	else
		previously_found = true;

	int gateindex = int_msg->getArrivalGate()->getIndex();
	__sface( table[chunk_id_without_representation].interfaces , gateindex );
	return previously_found;
}

// Returns a valid pit entry if it exists. Otherwise returns a pit_entry with interface==0
pit_entry PIT::handle_data(ccn_data* data_msg)
{
    chunk_t chunk_id = data_msg -> getChunk(); //Get information about the file

	// PIT entries are indexed ignoring the representation mask
	__srepresentation_mask(chunk_id, 0x0000);
    unordered_map < chunk_t , pit_entry >::iterator it = table.find(chunk_id);

	pit_entry return_value;
    if ( it != table.end() )
		return_value = it->second;
	else{
		pit_entry invalid;
		invalid.interfaces = 0; // This is the way to signal that no pit entry has been found
		return_value = invalid;
	}
    table.erase(chunk_id); //erase pending interests for that chunk

	return return_value;
}
//</aa>

