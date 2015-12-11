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
#ifndef REPRESENTATION_HANDLER_H
#define REPRESENTATION_HANDLER_H
#include <omnetpp.h>
#include "ccnsim.h"

//<aa>
#include "ccn_data.h"


using namespace std;

//<aa>
class RepresentationHandler
{
	public:
		RepresentationHandler(const char* bitrates);
		const unsigned short get_num_of_representations();
		const double get_bitrate(unsigned short representation);
		const unsigned get_storage_space_of_representation(unsigned short representation);

		const unsigned get_storage_space_of_chunk(chunk_t chunk_id);	// Check what is the representation
																		// of the chunk and returns the
																		// required storage space in terms
																		// of slots

		unsigned short get_representation_number(chunk_t chunk_id) const;
		const representation_mask_t set_bit_to_zero(representation_mask_t mask, unsigned short position);
		const representation_mask_t get_representation_mask(ccn_data* data) const;
		const representation_mask_t get_possible_representation_mask() const;
		const bool is_it_compatible(chunk_t present, chunk_t req) const;

		#ifdef SEVERE_DEBUG
		void check_if_correct();
		const char* dump_storage();
		const char* dump_bitrates();
		const char* dump_utilities();
		const char* dump_chunk(chunk_t cid);
		void check_representation_mask(chunk_t chunk_id, unsigned pkt_type) const;
		#endif


	private:
		vector<double> representation_bitrates;
		vector<unsigned> representation_storage_space; // Associate to each representation the required
															// storage space, as a multiple of the space of
															// the lowest representation
		representation_mask_t possible_representation_mask;
};
//</aa>
#endif

