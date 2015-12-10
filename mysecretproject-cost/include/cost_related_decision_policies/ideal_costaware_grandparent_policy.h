/*
 * ccnSim is a scalable chunk-level simulator for Content Centric
 * Networks (CCN), that we developed in the context of ANR Connect
 * (http://www.anr-connect.org/)
 *
 * People:
 *    Giuseppe Rossini (lead developer, mailto giuseppe.rossini@enst.fr)
 *    Raffaele Chiocchetti (developer, mailto raffaele.chiocchetti@gmail.com)
 *    Dario Rossi (occasional debugger, mailto dario.rossi@enst.fr)
 *    Andrea Araldo (mailto andrea.araldo@gmail.com)
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
#ifndef IDEAL_COSTAWARE_GRANDPARENT_POLICY_H_
#define IDEAL_COSTAWARE_GRANDPARENT_POLICY_H_

//<aa>
#include "decision_policy.h"
#include "error_handling.h"
#include "costaware_ancestor_policy.h"
#include "lru_cache.h"
#include "WeightedContentDistribution.h"

// This is an abstract class

// This class represent a decision policy that decides to cache an object only if the new 
// object has a weight greater than the eviction candidate. Doing this way, the insertion
// of the new object makes the cache content "more valuable".
// See data_to_cache(..) to understand better.
class Ideal_costaware_grandparent: public Costaware_ancestor{
	protected:
		double alpha;
		lru_cache* mycache; // cache I'm attached to

    public:
		Ideal_costaware_grandparent(double average_decision_ratio_, base_cache* mycache_par):
			Costaware_ancestor(average_decision_ratio_)
		{

			if (kappa>1 || kappa<0){
				std::stringstream ermsg; 
				ermsg<<"kappa="<<kappa<<" is not valid";
				severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
			}
			alpha = content_distribution_module->get_alpha();
			mycache = dynamic_cast<lru_cache*>(mycache_par);

			// CHECK{
				if( mycache == NULL ){
					std::stringstream ermsg; 
					ermsg<<"This policy works only with lru";
					severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
				}
			// }CHECK

		};

		virtual bool data_to_cache(ccn_data * data_msg)
		{
			bool decision;

			#ifdef SEVERE_DEBUG
			if( !mycache->is_initialized() ){
				std::stringstream ermsg; 
				ermsg<<"base_cache is not initialized.";
				severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
			}
			#endif

			chunk_t content_index = data_msg->getChunk();
			double price = data_msg->getPrice();

			if (mycache->get_occupied_slots() < mycache->get_slots() )
				decision = decide_with_cache_not_full(content_index, price);
			else{

				double new_content_weight = compute_content_weight(content_index,price);


				cache_item_descriptor* lru_element_descriptor = mycache->get_lru();
				content_index = lru_element_descriptor->k;
				price = lru_element_descriptor->get_price();
				double lru_weight = compute_content_weight(content_index,price);

				if (new_content_weight > lru_weight)
					// Inserting this content in the cache would make it better
					decision = true;

				// a small kappa means that we tend to renew the cache often

				else if ( dblrand() < kappa )
					decision = false;
				else
					decision = true;
			}

			return decision;
		};

		virtual double compute_correction_factor(){
			return 0;
		};

		virtual double compute_content_weight(chunk_t id, double price)=0; // This is an abstract class
		virtual bool decide_with_cache_not_full(chunk_t id, double price)=0;
};
//<//aa>
#endif

