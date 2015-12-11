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
#ifndef DATA_H_
#define DATA_H_
#include "ccnsim.h"
#include "ccn_data_m.h"
#include <deque>
#include <algorithm>

//<aa>
#include "error_handling.h"
//</aa>

class ccn_data: public ccn_data_Base{
protected:

	std::deque<int> path;

public:
	ccn_data(const char *name=NULL, int kind=0):ccn_data_Base(name,kind){;}
	ccn_data(const ccn_data_Base& other) : ccn_data_Base(other.getName() ){ operator=(other); }
	ccn_data& operator=(const ccn_data& other){
		if (&other==this) return *this;
		ccn_data_Base::operator=(other);
		path = other.path;
		return *this;
	}

	//<aa> const keyword is needed when using graphical interface (Cesar Berdardini suggestion) </aa>
	virtual ccn_data *dup() const {return new ccn_data(*this);} 

	//Utility functions which return 
	//different header fields of the packet
	uint32_t get_name()
	{
	        std::stringstream ermsg; 
			ermsg<<"In this version of ccnSim, get_name() has been replaced by get_object_id()."
				<<" Please, use the new function";
		    severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
			return 1;
	};

	const chunk_t get_chunk_id() const { return chunk_var;}
	uint32_t get_object_id(){ return __id(chunk_var);}
	uint32_t get_chunk_num(){ return __chunk(chunk_var);}
	uint64_t get_next_chunk(){ return next_chunk(chunk_var); }

};
Register_Class(ccn_data);
#endif 
