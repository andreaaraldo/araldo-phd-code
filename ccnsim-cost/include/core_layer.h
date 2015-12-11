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

#ifndef CCN_NODE_H
#define CCN_NODE_H

#include <omnetpp.h>
#include "ccnsim.h"

#include <boost/unordered_map.hpp>
#include <boost/unordered_set.hpp>

//<aa>
#include "repository/Repository.h"
#include "PIT.h"
//</aa>

using namespace std;
using namespace boost;

class ccn_interest;
class ccn_data;

class strategy_layer;
class base_cache;




//<aa>
typedef struct iface_stats
{
	double slots_sent; // slots sent on the interface. slots are the unity of measure of the cache
} iface_stats_t;
//</aa>

class core_layer : public abstract_node
{
    friend class statistics;
    
    public:
    	void check_if_correct(int line);
		//<aa>
		#ifdef SEVERE_DEBUG
		bool it_has_a_repo_attached;

		vector<int> get_interfaces_in_PIT(chunk_t chunk);
		bool is_it_initialized;
		bool i_am_initializing; //true only during module initialization
		client* get_client_attached_to_core_layer_interface(int interface);
		#endif

		const Repository* get_attached_repository();
		//</aa>

    protected:
		//Standard node Omnet++ functions
		virtual void initialize();
		virtual void handleMessage(cMessage *);
		virtual void finish();

		//<aa> See ned file
		bool interest_aggregation;
		bool transparent_to_hops;

		vector<cGate*> gates;

		void add_to_pit(chunk_t chunk, int gate);
		iface_stats_t* iface_stats; //An array of per-interface statistics
		virtual void initialize_iface_stats();
		Repository* repository;
		virtual Repository* create_repository();

		bool* is_face_to_client;	// is_face_to_client is true if face i is
									// attached to a client
		unsigned face_cardinality;// The number of interfaces (including the one connected
								  // to the proactive component)

		bool cache_if_in_repo;	// if yes, the cache can store a chunk
								// that is served by the attached repo
		//</aa>

		//Custom functions
		void handle_interest(ccn_interest *);
		void handle_ghost(ccn_interest *);
		void handle_data(ccn_data *);
		void handle_decision(bool *, ccn_interest *);


		bool check_ownership(vector<int>);
		ccn_data *compose_data(chunk_t chunk_id);
		void clear_stat();


    private:
		unsigned long max_pit;
		unsigned short nodes;
		double my_btw;
	

		//Architecture data structures
		PIT* pit;
		base_cache *ContentStore;
		strategy_layer *strategy;

		//Statistics
		int interests;
		int data;

		//<aa>
		#ifdef SEVERE_DEBUG
		int unsolicited_data;	// Data received by the node but not requested by anyone

		int discarded_interests; //number of incoming interests discarded
								 // because their TTL is > max hops
		int unsatisfied_interests;	//number of interests for contents that are neither
									//in the cache nor in the repository of this node	
		int interests_satisfied_by_cache;

		#endif
		int	send_data (ccn_data* msg, const char *gatename, int gateindex, int line_of_the_call);
		//</aa>
};
#endif

