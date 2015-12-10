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
#include "RepresentationAwareClient.h"

#include <iostream>
#include "error_handling.h"

Register_Class (RepresentationAwareClient);

void RepresentationAwareClient::initialize()
{
	client::initialize();
	unsigned short num_of_repr =
		content_distribution::get_repr_h()->get_num_of_representations( );
	repr_downloaded = (unsigned long*) calloc(num_of_repr, sizeof(unsigned long) );
}

bool RepresentationAwareClient::handle_incoming_chunk(ccn_data *data_message)
{
	bool is_chunk_expected = client::handle_incoming_chunk (data_message);
	if (is_chunk_expected)
	{
		unsigned repr = content_distribution::get_repr_h()->get_representation_number(data_message->getChunk() );
		repr_downloaded[repr-1]++;
	}
	return is_chunk_expected;
}

void RepresentationAwareClient::clear_stat()
{
	client::clear_stat();
	unsigned short num_of_repr =
		content_distribution::get_repr_h()->get_num_of_representations( );
	memset( repr_downloaded, 0, num_of_repr * sizeof(unsigned long) );
}


const unsigned long* RepresentationAwareClient::get_repr_downloaded() const
{
	return repr_downloaded;
}
//</aa>

