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
#ifndef TWO_LRU_POLICY_H_
#define TWO_LRU_POLICY_H_

#include "decision_policy.h"
#include "base_cache.h"
#include "lru_cache.h"

#include "error_handling.h"

/*
 * 2-LRU policy: although being a meta-caching algorithm, it requires nodes to allocate a second cache, namely
 * 				 Name Cache (always with LRU replacement), in order to keep track of the IDs of the received Interest packets.
 * 				 In case of a HIT inside the Name Cache, the retrieved Data packet will be cached in the normal
 * 				 cache (i.e., the one that contains real contents); otherwise, it will be just forwarded back.
 */

class Two_Lru: public DecisionPolicy
{
    public:
	Two_Lru(uint32_t cSize):ncSize(cSize){
		base_cache* bcPointer = new lru_cache();	// Create a new LRU cache that will act as a Name Cache.
		name_cache = dynamic_cast<lru_cache *> (bcPointer);
		name_cache->set_size(ncSize);}				// Set the size of the Name Cache.

	/*
	 * Cache decision of the 2-LRU. Since the flag that indicates the decision (cache or not) is present inside
	 * the PIT entry, and it has already been set by the core_layer, this function returns always true.
	 */
	virtual bool data_to_cache(ccn_data *)
	{
		return true;
	}

	/*
	 *  Check the presence of the content ID inside the Name Cache, and eventually stores it.
	 */
	bool name_to_cache(ccn_interest *int_msg)
	{
		chunk_t chunk = int_msg->getChunk();
		if (name_cache->lookup_name(chunk))
		{
			// The ID is already present inside the Name Cache, so update its position and return True.
			// As a consequence, the 'cacheable' flag inside the PIT will be set to 1.
			return true;
		}
		else
		{
			// The ID is NOT present inside the Name Cache, so insert it and return False.
			// As a consequence, the 'cacheable' flag inside the PIT will be set to 0.
			name_cache->store_name(chunk);
			return false;
		}
	}

    private:
	lru_cache* name_cache;
	uint32_t ncSize;		// Size of the Name Cache in terms of number of content IDs.
};
#endif

