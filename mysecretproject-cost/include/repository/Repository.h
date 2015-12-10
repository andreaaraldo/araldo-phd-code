/*
 * ccnSim is a scalable chunk-level simulator for Content Centric
 * Networks (CCN), that we developed in the context of ANR Connect
 * (http://www.anr-connect.org/)
 *
 * People:
 *    Giuseppe Rossini (lead developer, mailto giuseppe.rossini@enst.fr)
 *    Andrea Araldo (andrea.araldo@gmail.com)
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
#ifndef REPOSITORY_H_
#define REPOSITORY_H_

#include "ccn_data.h"
#include "ccn_interest.h"
#include "RepresentationSelector.h"


class Repository {
    public:
		Repository(int attached_node_index_, int repo_index_, double price_);
		virtual double get_price() const;

		// Returns the chunk_id that the repo is providing or 0 if the repo does not 
		// own the requested chunk
		virtual chunk_t handle_interest(ccn_interest* int_msg) ;

		virtual void finish(cComponent* parentModule) const;
		virtual void clear_stat();

		virtual int get_repo_load() const;


	protected:
		unsigned int bitmask;
		int attached_node_index;
		int repo_index;
		double price;		

		//<aa> number of chunks satisfied by the repository attached to this node</aa>
		int repo_load;

		// A repository will always send the lowest among the requested and available 
		// representation
		RepresentationSelectorLowest representation_selector; 

		
};
#endif
//</aa>
