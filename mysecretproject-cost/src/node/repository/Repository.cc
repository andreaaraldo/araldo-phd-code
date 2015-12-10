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
#include "error_handling.h"
#include "repository/Repository.h"
#include "statistics.h"
#include <iostream>

//Register_Class(lru_cache);

Repository::Repository(int attached_node_index_, int repo_index_, double price_)
{
	attached_node_index = attached_node_index_;
	repo_index = repo_index_;
	price = price_;
	bitmask = 0; 
	clear_stat();

	#ifdef SEVERE_DEBUG
	if( (unsigned)repo_index > sizeof(bitmask)*8 )
	{
		std::stringstream msg; 
		msg<<"Trying to consider the "<<repo_index_<< "-th repository, while the maximum number can only be "<<
			sizeof(bitmask);
		severe_error(__FILE__, __LINE__, msg.str().c_str() );
	}
	#endif
    bitmask = (1<<repo_index);	// Recall that the width of the repository bitset is only num_repos
}



double Repository::get_price() const
{
	return price;
}

/**
 * Returns the chunk_id that the repo is providing or 0 if the repo does not own the requested chunk
 * 
*/
chunk_t Repository::handle_interest(ccn_interest* int_msg)
{
	chunk_t chunk_to_deliver = 0;

	#ifdef SEVERE_DEBUG
		content_distribution::get_repr_h()->check_representation_mask(int_msg->getChunk(), CCN_I );
	#endif


	if (bitmask & content_distribution::get_repos( int_msg->get_object_id() ) )
	{

		// This repo contains the object
		repo_load++;

		// By definition, a repository contains all the possible representations of the served objects
		representation_mask_t available = (	0xFFFF);
		representation_mask_t representation_mask = representation_selector.select(
										int_msg->get_representation_mask(), available);

		#ifdef SEVERE_DEBUG
		if (representation_mask == 0)
		{
			std::stringstream ermsg;
			ermsg<<"The interest "<< __id(int_msg->getChunk() )<< ":"<< __chunk(int_msg->getChunk() )<<":"<<
				__representation_mask(int_msg->getChunk() )<< " arrived to the repo is not correct";
			severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
		}
		#endif
		
		chunk_to_deliver = int_msg->getChunk();
		__srepresentation_mask(chunk_to_deliver, representation_mask);
	}
	return chunk_to_deliver;
}

//	Print node statistics
void Repository::finish( cComponent* parentModule) const
{
    char name [30];

    if (repo_load != 0)
	{
		sprintf ( name, "repo_load[%d]", attached_node_index);
		parentModule->recordScalar(name,repo_load);
    }
}

void Repository::clear_stat()
{
	repo_load = 0;
}

int Repository::get_repo_load() const
{
	return repo_load;
}
//</aa>

