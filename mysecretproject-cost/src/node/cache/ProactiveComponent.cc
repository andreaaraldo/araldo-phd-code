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
#include "ProactiveComponent.h"
#include "content_distribution.h"

Register_Class(ProactiveComponent);

void ProactiveComponent::initialize()
{
	client::initialize();
	proactive_probability = par("proactive_probability");
}

void ProactiveComponent::try_to_improve(chunk_t stored, chunk_t requested_chunk_id)
{
	Enter_Method("Requesting a chunk"); // If you do not add this invocation and you call this
											// method from another C++ class, an error will raise.
											// Search the manual for "Enter_Method" for more information

	if ( dblrand() <= proactive_probability)
	{
		unsigned short representation_found =
			content_distribution::get_repr_h()->get_representation_number(stored);

		// Try to retrieve a better representation of this chunk
		representation_mask_t request_mask = __representation_mask(requested_chunk_id);
		representation_mask_t improving_mask = (0xFFFF << representation_found );
		improving_mask = (improving_mask & request_mask);

		#ifdef SEVERE_DEBUG
		representation_mask_t stored_mask = __representation_mask(stored);
		if( (improving_mask & 0x0001) != 0 )
		{
			std::stringstream ermsg;
			ermsg<< "An improving mask cannot ask for repr 1. This would not be an improvement."<<
				"request_mask="<<request_mask<<"; stored_mask="<<stored_mask<<"; representation_found="<<
				representation_found;
			severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
		}
		#endif

		if (improving_mask != 0x0000)
		{	// There exists a higher representation and I want to retrieve it
			name_t object_id = __id(stored);
			cnumber_t chunk_num = __chunk(stored);
			request_specific_chunk(object_id, chunk_num, improving_mask);
		}
	}
}


void ProactiveComponent::proactively_catch_a_chunk(chunk_t object_id, cnumber_t chunk_num,
        representation_mask_t repr_mask)
{
    Enter_Method_Silent(); // If you do not add this invocation and you call this
										// method from another C++ class, an error will raise.
										// Search the manual for "Enter_Method" for more information
    request_specific_chunk(object_id, chunk_num, repr_mask);
}

void ProactiveComponent::request_specific_chunk(name_t object_id, cnumber_t chunk_num,
		representation_mask_t repr_mask)
{
	multimap < name_t, download>::iterator it = current_downloads.find(object_id);
	if (	it == current_downloads.end() ||
			it->second.repr_mask != repr_mask
	){
		// I request a chunk only if I am not currently already waiting for it
	    client::request_specific_chunk(object_id, chunk_num, repr_mask);
	}
}

//</aa>

