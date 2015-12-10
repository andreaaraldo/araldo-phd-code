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

#include "ccnsim.h"
#include "RepresentationHandler.h"
#include "content_distribution.h"
#include <error_handling.h>
#include <core_layer.h>
#include "ccn_data.h"

RepresentationHandler::RepresentationHandler(const char* bitrates)
{
	representation_bitrates = cStringTokenizer(bitrates,"_").asDoubleVector();

	// {COMPUTE STORAGE
		// I impose that the lowest representation occupies 100 slots, in order to
		// guarantee the double
		// decimal precision when computing the other storage spaces
		unsigned low_repr_slots = 100;
		representation_storage_space.push_back(low_repr_slots);

		for (unsigned i=1 ; i < representation_bitrates.size() ; i++)
		{
			// The slots needed for a certain representation are denoted as a multiple of the slots
			// needed for the lowest representation.
			representation_storage_space.push_back(
				round( representation_bitrates[i]*low_repr_slots / (float)representation_bitrates[0] ) );
		}
	// }COMPUTE STORAGE

	possible_representation_mask = ( (0xFFFF << get_num_of_representations() ) & 0xFFFF);
	possible_representation_mask = (~possible_representation_mask);

	#ifdef SEVERE_DEBUG
			check_if_correct();
	#endif


	//{ CHECK INPUT
	unsigned storage_temp = get_storage_space_of_representation(1);
	for (unsigned i = 2; i <= get_num_of_representations(); i++)
	{
		if (get_storage_space_of_representation(i) < storage_temp)
			severe_error(__FILE__,__LINE__, 
						"The representation should be specified in increasing quality order");
		storage_temp = get_storage_space_of_representation(i);
	}
	//} CHECK INPUT

}

const representation_mask_t RepresentationHandler::get_possible_representation_mask() const
{
	return possible_representation_mask;
}

unsigned short RepresentationHandler::get_representation_number(chunk_t chunk_id) const
{
	unsigned short representation = 0;
	representation_mask_t repr_mask = __representation_mask(chunk_id);
	unsigned short i=1; while (representation == 0 && i<=representation_bitrates.size() )
	{
		if( (repr_mask >> i ) == 0 )
			representation = i;
		i++;
	}

	return representation;
}

const unsigned RepresentationHandler::get_storage_space_of_chunk(chunk_t chunk_id) 
{
	#ifdef SEVERE_DEBUG
		check_representation_mask(chunk_id, CCN_D);
	#endif

	return get_storage_space_of_representation(get_representation_number(chunk_id));
}

const double RepresentationHandler::get_bitrate(unsigned short representation)
{
	return representation_bitrates[representation-1];
}

const unsigned RepresentationHandler::get_storage_space_of_representation(unsigned short representation)
{
	#ifdef SEVERE_DEBUG
	if (representation == 0)
	{
			std::stringstream ermsg; 
			ermsg<<"Representation 0 does not exist";
			severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
	}	
	#endif

	unsigned space = representation_storage_space[representation-1];

	#ifdef SEVERE_DEBUG
	if (space == 0)
	{
			std::stringstream ermsg; 
			ermsg<<"Representation cannot require 0 space";
			severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
	}	
	#endif
	return space;
}

const unsigned short RepresentationHandler::get_num_of_representations() 
{
	return representation_storage_space.size();
}

const representation_mask_t RepresentationHandler::set_bit_to_zero(representation_mask_t mask, unsigned short position)
{
	representation_mask_t adjoint = (0x0001 << (position-1) );
	return ~( (~mask) | adjoint);
}

const bool RepresentationHandler::is_it_compatible(chunk_t present, chunk_t req) const
{
	representation_mask_t stored_mask = __representation_mask(present);
	representation_mask_t request_mask = __representation_mask(req);
	representation_mask_t intersection = stored_mask & request_mask;
	return (bool) intersection;
}



#ifdef SEVERE_DEBUG
const char* RepresentationHandler::dump_storage()
{
	std::stringstream result;
	for (unsigned i=0 ; i < representation_storage_space.size() ; i++)
		result<< representation_storage_space[i]<<":";
	return result.str().c_str();
}

const char* RepresentationHandler::dump_bitrates()
{
	std::stringstream result;
	for (unsigned i=0 ; i < representation_bitrates.size() ; i++)
		result<< representation_bitrates[i]<<":";
	return result.str().c_str();
}


// Check if the representation mask denotes one and only one representation
void RepresentationHandler::check_representation_mask(chunk_t chunk_id, unsigned pkt_type) const
{
	representation_mask_t representation_mask = __representation_mask(chunk_id);

	switch(pkt_type)
	{
		case (CCN_D):
		{
			if (representation_mask == 0)
			{
			    std::stringstream ermsg;
			    ermsg<<"Checking chunk "<<__id(chunk_id)<<":"<<__chunk(chunk_id)<<":"<<
			    		__representation_mask(chunk_id)<<". ";
				ermsg<<"No representation is recognizable since representation mask is zero";
				severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
			}		


			unsigned short representation = 0;
			unsigned short i=1;
			while (representation == 0 && i<= content_distribution::get_repr_h()->get_num_of_representations() )
			{
				if( (representation_mask >> i ) == 0 )
					representation = i;
				i++;
			}

			if ( (possible_representation_mask & representation_mask) ==0 ||representation == 0 )
			{
			    std::stringstream ermsg; 
				ermsg<<"Invalid bitmask: no representation is recognizable. object_id:chunk_number:repr_mask="
					<<__id(chunk_id)<<":"<<__chunk(chunk_id)<<":"<<__representation_mask(chunk_id);
				severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
			}		

			unsigned short representation2 = 0;
			unsigned short j=0;
			bool found = false;

			while (representation2 == 0 )
			{			
				j++;
				if( ( (representation_mask << j ) & 0x000000000000FFFF) == 0 )
				{
					representation2 = sizeof(representation_mask)*8-j+1;
					found = true;
				}
			}
			if (representation2 != representation)
			{
			    std::stringstream ermsg; 
				ermsg<<"Invalid bitmask: there is more than one 1. object_id:chunk_number:representation_mask="
					<<__id(chunk_id)<<":"<<__chunk(chunk_id)<<":"<<__representation_mask(chunk_id)<<
					" representation="<<representation <<"; representation2="<<representation2<<"; j="<<j<<
					"; sizeof(representation_mask="<<sizeof(representation_mask)<<"; found="<<found;
				severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
			}
			break;
		}

		case (CCN_I):
		{
			if ( (representation_mask &  0xFFFF) == 0)
			{
			    std::stringstream ermsg; 
				ermsg<<"You are requesting a representation "<< representation_mask<<" that is incorrect";
				severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
			}
			break;
		}

		default:
        {
            std::stringstream ermsg;
            ermsg<<"unrecognized pkt type "<< pkt_type;
			severe_error(__FILE__,__LINE__, ermsg.str().c_str());
		}
	}
};

void RepresentationHandler::check_if_correct()
{
	if ( 	representation_storage_space.size()!=representation_bitrates.size()
	){
		std::stringstream ermsg;
		ermsg<<"representation_bitrates.size()="<<representation_bitrates.size()<<
			"; representation_storage_space.size()="<<representation_storage_space.size();
		severe_error(__FILE__,__LINE__,ermsg.str().c_str());
	}

}

const char* RepresentationHandler::dump_chunk(chunk_t cid)
{
	std::stringstream ret;
	ret<<__id(cid)<<":"<<__chunk(cid)<<":"<<__representation_mask(cid);
	return ret.str().c_str();
}

#endif

//</aa>
