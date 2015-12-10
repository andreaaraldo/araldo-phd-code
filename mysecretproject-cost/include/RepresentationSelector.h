/*
 * ccnSim is a scalable chunk-level simulator for Content Centric
 * Networks (CCN), that we developed in the context of ANR Connect
 * (http://www.anr-connect.org/)
 *
 * People:
 *    Giuseppe Rossini (lead developer, mailto giuseppe.rossini@enst.fr)
 *	  Andrea Araldo (mailto: andrea.araldo@gmail.com)
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
#ifndef REPRESENTATION_SELECTOR_H_
#define REPRESENTATION_SELECTOR_H_

//<aa>

#include "ccnsim.h"
#include "error_handling.h"
#include "content_distribution.h"

class RepresentationSelector
{
    public:
		explicit RepresentationSelector(){}

		// The input parameters are binary strings. 
		// available indicates the available representations, while req the requested ones.
		// This function selects one of the requested representations among the available.
		virtual const representation_mask_t select(representation_mask_t available, representation_mask_t req) const = 0;
};

class RepresentationSelectorSimple: public RepresentationSelector
{
	public:
		const representation_mask_t select(representation_mask_t req,representation_mask_t available) const
		{
			return 1;
		}
};

class RepresentationSelectorLowest: public RepresentationSelector
{
	public:
		const representation_mask_t select(representation_mask_t req,representation_mask_t available) const
		{
			representation_mask_t req_and_available = (req & available);
			representation_mask_t filter = 0x0001;
			unsigned i = 0;
			while ( ( filter & req_and_available) == 0 && 
						i < content_distribution::get_repr_h()->get_num_of_representations() )
			{
				filter = filter<<1;
				i++;
			}
			if (i < content_distribution::get_repr_h()->get_num_of_representations() )
			{
				return filter;
			}
			else return 0;
		}
};
//</aa>
#endif
