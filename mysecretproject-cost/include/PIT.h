/*
 * ccnSim is a scalable chunk-level simulator for Content Centric
 * Networks (CCN), that we developed in the context of ANR Connect
 * (http://www.anr-connect.org/)
 *
 * People:
 *    Giuseppe Rossini (lead developer, mailto giuseppe.rossini@enst.fr)
 *	  Andrea Araldo (andrea.araldo@gmail.com)
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
#ifndef PIT_H_
#define PIT_H_


#include "ccnsim.h"
//<aa>
#include "error_handling.h"
#include "content_distribution.h"
#include "statistics.h"
//</aa>
//This structure takes care of data forwarding
struct pit_entry 
{
    interface_t interfaces;
    unordered_set<int> nonces;
    simtime_t time; //<aa> last time this entry has been updated</aa>
    std::bitset<1> cacheable;		// Bit indicating if the retrieved Data packet should be cached or not.
};


class PIT
{
    protected:
		boost::unordered_map <chunk_t, pit_entry> table;
		double RTT; // Round Trip Time. We will use this value to decide whether to remove a PIT entry	

	public:
		PIT(double RTT);

		// If no entry exists for the requested object a new entry is inserted and
		// a NULL pointer is returned.
		// If a previous PIT entry is found, it is updated adding to the related 
		// interfaces, the one where this interest comes from.
		bool handle_interest(ccn_interest *int_msg, bool cacheable);

		// If a PIT entry related to the incoming data is found, it is consumed (thus removed)
		pit_entry handle_data(ccn_data* data_msg);
};

#endif
