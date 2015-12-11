/*
 * ccnSim is a scalable chunk-level simulator for Content Centric
 * Networks (CCN), that we developed in the context of ANR Connect
 * (http://www.anr-connect.org/)
 *
 * People:
 *    Giuseppe Rossini (lead developer)
 *    Raffaele Chiocchetti (developer)
 *    Dario Rossi (occasional debugger)
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
#include "core_layer.h"
#include "ccnsim.h"
#include <algorithm>

#include "content_distribution.h"
#include "strategy_layer.h"
#include "ccn_interest.h"
#include "ccn_data.h"
#include "base_cache.h"
#include "two_lru_policy.h"
//<aa>
#include "error_handling.h"
#include "repository/Repository.h"
#include "PIT.h"
#include "RepresentationHandler.h"
//</aa>

Register_Class(core_layer);


void  core_layer::initialize()
{
	//<aa>
	#ifdef SEVERE_DEBUG
		i_am_initializing = true;
		is_it_initialized = false;
		it_has_a_repo_attached = false;
	#endif
	interest_aggregation = par("interest_aggregation");
	transparent_to_hops = par("transparent_to_hops");
	// Notice that repo_price has been initalized by WeightedContentDistribution
	cache_if_in_repo = getAncestorPar("cache_if_in_repo");
	//</aa>
 
	double RTT = par("RTT");
    nodes = getAncestorPar("n"); //Number of nodes
    my_btw = getAncestorPar("betweenness");


    //Getting the content store
    ContentStore = (base_cache *) gate("cache_port$o")->getNextGate()->getOwner();
    strategy = (strategy_layer *) gate("strategy_port$o")->getNextGate()->getOwner();

	//<aa>
	initialize_iface_stats();
	repository = create_repository();

	#ifdef SEVERE_DEBUG
		it_has_a_repo_attached = true;
	#endif


	clear_stat();

	#ifdef SEVERE_DEBUG
	check_if_correct(__LINE__);
	is_it_initialized = true;

	if (gateSize("face$o") > (int) sizeof(interface_t)*8 )
	{
		std::stringstream msg;
		msg<<"Node "<<getIndex()<<" has "<<gateSize("face$o")<<" output ports. But the maximum "
			<<"number of interfaces manageable by ccnsim is "<<sizeof(interface_t)*8 <<
			" beacause the type of "
			<<"interface_t is of size "<<sizeof(interface_t)<<" bytes. You can change the definition of "
			<<"interface_t (in ccnsim.h) to solve this issue and recompile";
		severe_error(__FILE__, __LINE__, msg.str().c_str() );
	}

	i_am_initializing = false;
	#endif

	pit = new PIT(RTT);

	//{ RETRIEVE CLIENT INTERFACES
		face_cardinality =  gateSize("face");
		is_face_to_client = (bool*) malloc( sizeof(bool)*face_cardinality );
		for (unsigned i = 0; i < face_cardinality; i++)
		{

			if ( 	gate("face$o",i)->getNextGate()->getOwnerModule()->getModuleType() ==
					cModuleType::find("modules.clients.ProactiveComponent") ||
					gate("face$o",i)->getNextGate()->getNextGate()->getOwnerModule()->getModuleType() ==
					cModuleType::find("modules.clients.client")
			)
				is_face_to_client[i] = true;
			else
				is_face_to_client[i] = false;
		}
	//} RETRIEVE CLIENT INTERFACES

	for (int j=0; j<gateSize("face$o") ; j++)
		gates.push_back( gate("face$o", j) );
	//</aa>
}

//<aa>
void core_layer::initialize_iface_stats()
{
	iface_stats = (iface_stats_t*) calloc(gateSize("face$o"), sizeof(iface_stats_t) );
}


Repository* core_layer::create_repository()
{
    int num_repos = getAncestorPar("num_repos");
	Repository* repository_ = NULL;
    int repo_index = 0;
    for (repo_index = 0; repo_index < num_repos; repo_index++)
	{
		if (content_distribution::repositories[repo_index] == getIndex() )
		{
			double price = content_distribution::repo_prices[repo_index]; 
			repository_ = new Repository(getIndex(), repo_index, price);
			break;
		} 
	}
	return repository_;
}
//</aa>

/*
 * Core layer core function. Here the incoming packet is classified,
 * determining if it is an interest or a data packet (the corresponding
 * counters are increased). The two auxiliar functions handle_interest() and
 * handle_data() have the task of dealing with interest and data processing.
 */
void core_layer::handleMessage(cMessage *in)
{
	//<aa>
	#ifdef SEVERE_DEBUG
		check_if_correct(__LINE__);
	#endif
	//</aa>


    ccn_data *data_msg;
    ccn_interest *int_msg;


    int type = in->getKind();
    switch(type){
    //On receiving interest
    case CCN_I:	
		interests++;

		int_msg = (ccn_interest *) in;

		//<aa>
		if (!transparent_to_hops)
		//</aa>
			int_msg->setHops(int_msg -> getHops() + 1);

		if (int_msg->getHops() == int_msg->getTTL())
		{
	    	//<aa>
	    	#ifdef SEVERE_DEBUG
	    	discarded_interests++;
	    	check_if_correct(__LINE__);
	    	#endif
	    	//</aa>
	    	break;
		}
		int_msg->setCapacity (int_msg->getCapacity() + ContentStore->get_slots());
		handle_interest (int_msg);
		break;

    //On receiving data
    case CCN_D:
		data++;

		data_msg = (ccn_data* ) in; //One hop more from the last caching node (useful for distance policy)

		//<aa>
		if (!transparent_to_hops)
		//</aa>
			data_msg->setHops(data_msg -> getHops() + 1);

		handle_data(data_msg);

		break;
    }

    delete in;
    
	//<aa>
	#ifdef SEVERE_DEBUG
	check_if_correct(__LINE__);
	#endif
	//</aa>
}

//	Print node statistics
void core_layer::finish()
{
	//<aa>
	#ifdef SEVERE_DEBUG
	check_if_correct(__LINE__);
	#endif
	//</aa>

    char name [30];

    //Total interests
	// <aa> Parts of these interests will be satisfied by the local cache; the remaining part will be sent to the local repo (if present) and partly sarisfied there. For the remaining part, a FIB entry will be searched to forward the intereset. If no FIB entry is found, the interest will be discarded </aa>
    sprintf ( name, "interests[%d]", getIndex());
    recordScalar (name, interests);

	if (repository != NULL)	
		repository->finish(this);

    //Total data
    sprintf ( name, "data[%d]", getIndex());
    recordScalar (name, data);

	//<aa>
	for (unsigned j=0; j<gates.size(); j++)
	{
		const char* this_gate = gates[j]->getFullName();
		cModule* attached_module = gates[j]->getNextGate()->getOwnerModule();
		if (attached_module == getParentModule() )
		{
			// this_gate is attached to a border gate of the node
			cGate* border_gate_of_this_node = gates[j]->getNextGate();
			const char* other_node = border_gate_of_this_node->getNextGate()->
												getOwnerModule()->getFullName();
			sprintf ( name, "slots_sent[%s->%s]", this_gate, other_node);
			recordScalar(name, iface_stats[j].slots_sent );
		}
			
		#ifdef SEVERE_DEBUG
		else if (attached_module->getModuleType() != 
				cModuleType::find("modules.clients.ProactiveComponent")
		){
			std::stringstream ermsg; 
			ermsg<<"Module attached to this gate was not recognised. Its type is "<< 
					attached_module->getModuleType();
			severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
		}	
		#endif
	}
	//</aa>
}




/* Handling incoming interests:
*  if an interest for a given content comes up: 
*     a) Check in your Content Store
*     b) Check if you are the source for that data. 
*     c) Put the interface within the PIT.
*/
void core_layer::handle_interest(ccn_interest *int_msg)
{
	//<aa>
	#ifdef SEVERE_DEBUG
		client* cli = get_client_attached_to_core_layer_interface( int_msg->getArrivalGate()->getIndex() );
		if (cli && !cli->is_active()  ) 
		{
			std::stringstream msg; 
			msg<<"I am node "<< getIndex()<<" and I received an interest from interface "<<
				int_msg->getArrivalGate()->getIndex()<<". This is an error since there is "<<
				"a deactivated client of type "<< cli->getModuleType() <<" attached there";
			debug_message(__FILE__, __LINE__, msg.str().c_str() );
		}
	#endif
	//</aa>

   chunk_t chunk = int_msg->getChunk();

   double int_btw = int_msg->getBtw();
   bool cacheable = true;  // This value indicates whether the retrieved content will be cached.
    
    // Check if the meta-caching is 2-LRU. In this case, we need to lookup for the content ID inside the Name Cache.
    string decision_policy = ContentStore->par("DS");
	//TODO: //<aa> move it in the initialization part, to do it only once</aa>

    if (decision_policy.compare("two_lru")==0)
    {
    	Two_Lru* tLruPointer = (Two_Lru *) (ContentStore->get_decisor());
    	if (!(tLruPointer->name_to_cache(int_msg)))	// The ID is not present inside the Name Cache, so the
    												// cacheable flag inside the PIT will be set to '0'.
    			cacheable = false;
    }

    chunk_t chunk_id_to_deliver = 0;
	cache_item_descriptor* cache_item = NULL;
	if ( (cache_item = ContentStore->handle_interest(chunk) ) != NULL )
	{
       // A corresponding item has been found in cache
		chunk_id_to_deliver = cache_item->k;
		ccn_data* data_msg = compose_data( chunk_id_to_deliver );

        data_msg->setHops(0);
        data_msg->setBtw(int_btw); //Copy the highest betweenness
        data_msg->setTarget(getIndex());
        data_msg->setFound(true);

        data_msg->setCapacity(int_msg->getCapacity());
        data_msg->setTSI(int_msg->getHops());
        data_msg->setTSB(1);

		//<aa> I transformed send in send_data</aa>
        send_data(data_msg,"face$o", int_msg->getArrivalGate()->getIndex(), __LINE__); 
        
        //<aa>
        #ifdef SEVERE_DEBUG
        interests_satisfied_by_cache++;
		check_if_correct(__LINE__);
        #endif
        //</aa>

	} else if ( repository!=NULL && (chunk_id_to_deliver = repository->handle_interest(int_msg ) ) )
	{	
			#ifdef SEVERE_DEBUG
				content_distribution::get_repr_h()->check_representation_mask(chunk_id_to_deliver, CCN_D );
			#endif

			//
			//b) Look locally (only if you own a repository)
			// we are mimicking a message sent to the repository
			//
		    ccn_data* data_msg = compose_data(chunk_id_to_deliver );
	
			//<aa>
			data_msg->setPrice(repository->get_price() ); 	// I fix in the data msg the cost of the object
											// that is the price of the repository
			//</aa>

		    data_msg->setHops(1);
		    data_msg->setTarget(getIndex());
			data_msg->setBtw(std::max(my_btw,int_btw));

			data_msg->setCapacity(int_msg->getCapacity());
			data_msg->setTSI(int_msg->getHops() + 1);
			data_msg->setTSB(1);
			data_msg->setFound(true);

			// Store the chunk in the local cache
			chunk_t evicted = 0;
		    bool decision = ContentStore->handle_data(data_msg, evicted, cache_if_in_repo);
		    // decision indicates whether the incoming chunk has been cached
		    ContentStore->after_handle_data(decision);

			//<aa> I transformed send in send_data</aa>
			send_data(data_msg,"face$o",int_msg->getArrivalGate()->getIndex(),__LINE__);

			//<aa>
			#ifdef SEVERE_DEBUG
			check_if_correct(__LINE__);
			#endif
			//</aa>
   } else {
        //
        //c) Put the interface within the PIT (and follow your FIB)
        //
   		//<aa>
		#ifdef SEVERE_DEBUG
			unsatisfied_interests++;
			check_if_correct(__LINE__);
		#endif
		//</aa>

		//<aa>
		bool i_will_forward_interest = false;
		//</aa>

		bool previously_found_in_pit = pit->handle_interest(int_msg, cacheable);
        if ( previously_found_in_pit==false )
		{
			//<aa> Replaces the lines
			//		bool * decision = strategy->get_decision(int_msg);
			//		handle_decision(decision,int_msg);
			// 		delete [] decision;//free memory for the decision array
			i_will_forward_interest = true;
			//</aa>
		}

		//<aa>
		if (int_msg->getTarget() == getIndex() )
		{	// I am the target of this interest but I have no more the object
			// Therefore, this interest cannot be aggregated with the others
			int_msg->setAggregate(false);
		}

		if ( !interest_aggregation || int_msg->getAggregate()==false )
			i_will_forward_interest = true;

		if (i_will_forward_interest)
		{  	bool * decision = strategy->get_decision(int_msg);
	    	handle_decision(decision,int_msg);
	    	delete [] decision;//free memory for the decision array
		}

		#ifdef SEVERE_DEBUG
			check_if_correct(__LINE__);

			client*  c = get_client_attached_to_core_layer_interface( int_msg->getArrivalGate()->getIndex() );
			if (c && !c->is_active() ){
				std::stringstream ermsg; 
				ermsg<<"Trying to add to the PIT an interface where a deactivated client is attached";
				severe_error(__FILE__,__LINE__,ermsg.str().c_str() );
			}
		#endif
		//</aa>
    }
    
    //<aa>
    #ifdef SEVERE_DEBUG
    	check_if_correct(__LINE__);
    #endif
    //</aa>
}


/*
 * Handle incoming data packets. First check within the PIT if there are
 * interfaces interested for the given content, then (try to) store the object
 * within your content store. Finally propagate the interests towards all the
 * interested interfaces.
 */
void core_layer::handle_data(ccn_data *data_msg)
{

    int i = 0;
    interface_t interfaces = 0;

	//<aa>
	#ifdef SEVERE_DEBUG
		int copies_sent = 0;
	#endif
	//</aa>

	pit_entry pentry = pit->handle_data(data_msg);

    if ( pentry.interfaces!=0 )
	{
		// A pit entry for this chunk was found
    	if (pentry.cacheable.test(0))
    	{	// Cache the content only if the cacheable bit is set.
    		chunk_t evicted = 0;
    		bool is_it_possible_to_cache = true; // There are no reasons, at the moment, to avoid this
    		bool decision = ContentStore->handle_data(data_msg, evicted, is_it_possible_to_cache);
    		// decision indicates whether the incoming chunk has been cached
    		ContentStore->after_handle_data(decision);
    	}

    	interfaces = pentry.interfaces;	// Get incoming interfaces.
		i = 0;
		while (interfaces)
		{
			if ( interfaces & 1 )
			{
				//<aa> I transformed send in send_data</aa>
				send_data(data_msg->dup(), "face$o", i,__LINE__ ); //follow bread crumbs back

				//<aa>
				#ifdef SEVERE_DEBUG
					copies_sent++;
				#endif
				//</aa>
			}
			i++;
			interfaces >>= 1;
		}
    } 
	//<aa> 
	// Otherwise the data are unrequested
	#ifdef SEVERE_DEBUG
		else unsolicited_data++;
		check_if_correct(__LINE__);
	#endif
	//</aa>
}


void core_layer::handle_decision(bool* decision,ccn_interest *interest)
{
	//<aa>
	#ifdef SEVERE_DEBUG
		bool interest_has_been_forwarded = false;
	#endif
	//</aa>

    if (my_btw > interest->getBtw())
		interest->setBtw(my_btw);

	// <aa> face_cardinality is the number of faces of core_layer while node_face_cardinality
	// is the number of faces of the node that contains this core_layer. Each core_layer face is attached
	// to a node face except the 1st, that is attached to the proative component
	// </aa>
    for (unsigned i = 1; i < face_cardinality; i++)
	{
		//<aa>
		#ifdef SEVERE_DEBUG
			if (decision[i-1] == true && is_face_to_client[i] )
			{
				chunk_t chunk_id = interest->getChunk();
				std::stringstream msg; 
				msg<<"I am node "<< getIndex()<<" and the node interface supposed to give"<<
					" access to chunk "<< __id(chunk_id)<<":"<<__chunk(chunk_id)<<":"<<__representation_mask(chunk_id) <<
					" is "<<i<<". This is impossible "<<
					" since that interface is to reach a client and you cannot access"
					<< " a content from a client ";
				severe_error(__FILE__, __LINE__, msg.str().c_str() );
			}
		#endif
		//</aa>

		if (decision[i-1] == true && !is_face_to_client[i]
			//&& interest->getArrivalGate()->getIndex() != i
		){
			sendDelayed(interest->dup(),interest->getDelay(),"face$o",i);
			#ifdef SEVERE_DEBUG
				interest_has_been_forwarded = true;
			#endif
		}
	}
	//<aa>
	#ifdef SEVERE_DEBUG
		if (! interest_has_been_forwarded)
		{
			int affirmative_decision_from_arrival_gate = 0;
			int affirmative_decision_from_client = 0;

			for (unsigned i = 0; i < face_cardinality; i++)
			{
				if (decision[i] == true)
				{
					if ( is_face_to_client[i] ){
						affirmative_decision_from_client++;
					}
					if ( (unsigned)interest->getArrivalGate()->getIndex() == i ){
						affirmative_decision_from_arrival_gate++;
					}
				}
			}
			std::stringstream msg; 
			msg<<"I am node "<< getIndex()<<" and interest for chunk "<<
				interest->getChunk()<<" has not been forwarded. ";
			severe_error(__FILE__, __LINE__, msg.str().c_str() );
		}
	#endif
}

// Check if the local node is the owner of the requested content.
bool core_layer::check_ownership(vector<int> repositories){
    bool check = false;
    if (find (repositories.begin(),repositories.end(),getIndex()) != repositories.end())
	check = true;
    return check;
}



/*
 * 	Create a Data packet in response to the received Interest.
 */
ccn_data* core_layer::compose_data(chunk_t chunk_id)
{
    ccn_data* data = new ccn_data("data",CCN_D);
	data->setSlotLength( content_distribution::get_repr_h()->get_storage_space_of_chunk(chunk_id) );
    data -> setChunk (chunk_id);
    data -> setHops(0);
    data->setTimestamp(simTime());

	#ifdef SEVERE_DEBUG
		content_distribution::get_repr_h()->check_representation_mask(chunk_id, CCN_D);
	#endif
    return data;
}

/*
 * Clear local statistics
 */
void core_layer::clear_stat(){
    interests = 0;
    data = 0;
    
    //<aa>
	if (repository !=NULL)
		repository->clear_stat();
    ContentStore->set_decision_yes(0);
	ContentStore->set_decision_no(0);
	
	//Reset the per-interface statistics
	memset(iface_stats, 0, sizeof(iface_stats_t)*gateSize("face$o") );
	

    
   	#ifdef SEVERE_DEBUG
	unsolicited_data = 0;
	discarded_interests = 0;
	unsatisfied_interests = 0;
	interests_satisfied_by_cache = 0;
	check_if_correct(__LINE__);
	#endif
    //</aa>
}

//<aa>
#ifdef SEVERE_DEBUG
void core_layer::check_if_correct(int line)
{
	int repo_load = get_attached_repository()==NULL? 0 : get_attached_repository()->get_repo_load();

	if ( repo_load != interests - discarded_interests - unsatisfied_interests
		-interests_satisfied_by_cache)
	{
			std::stringstream msg; 
			msg<<"node["<<getIndex()<<"]: "<<
				"repo_load="<<get_attached_repository()->get_repo_load() <<"; interests="<<interests<<
				"; discarded_interests="<<discarded_interests<<
				"; unsatisfied_interests="<<unsatisfied_interests<<
				"; interests_satisfied_by_cache="<<interests_satisfied_by_cache;
		    severe_error(__FILE__, line, msg.str().c_str() );
	}


	if (	ContentStore->get_decision_yes() + ContentStore->get_decision_no() +  
						(unsigned) unsolicited_data
						!=  (unsigned) data + repo_load
	){
					std::stringstream ermsg; 
					ermsg<<"caches["<<getIndex()<<"]->decision_yes="<<ContentStore->get_decision_yes()<<
						"; caches[i]->decision_no="<< ContentStore->get_decision_no()<<
						"; cores[i]->data="<< data
						<<"; cores[i]->repo_load="<< get_attached_repository()->get_repo_load()<<
						"; cores[i]->unsolicited_data="<< unsolicited_data<<
						". The sum of "<< "decision_yes + decision_no + unsolicited_data must be data";
					severe_error(__FILE__,line,ermsg.str().c_str() );
	}

	ContentStore->check_if_correct();
} //end of check_if_correct(..)
#endif

const Repository* core_layer::get_attached_repository()
{
	#ifdef SEVERE_DEBUG
	if (!is_it_initialized and ! i_am_initializing)
	{
			std::stringstream msg; 
			msg<<"I am node "<< getIndex()<<". Someone called this method before I was"
				" initialized";
			severe_error(__FILE__, __LINE__, msg.str().c_str() );
	}
	#endif
	return repository;
}


int	core_layer::send_data(ccn_data* msg, const char *gatename, int gateindex, int line_of_the_call)
{
	//{CHECKS
		#ifdef SEVERE_DEBUG
		if (gateindex > gateSize("face$o")-1 )
		{
			std::stringstream msg;
			msg<<"I am node "<<getIndex() <<". Line "<<line_of_the_call<<
				" commands you to send a packet to interface "<<gateindex<<
				". But the number of ports is "<<gateSize("face$o");
			severe_error(__FILE__, __LINE__, msg.str().c_str() );
		}

		if ( gateindex > (int) sizeof(interface_t)*8-1 )
		{
			std::stringstream msg;
			msg<<"You are trying to send a packet through the interface gateindex. But the maximum interface "
				<<"number manageable by ccnsim is "<<sizeof(interface_t)*8-1 <<" beacause the type of "
				<<"interface_t is of size "<<sizeof(interface_t)<<". You can change the definition of "
				<<"interface_t (in ccnsim.h) to solve this issue and recompile";
			severe_error(__FILE__, __LINE__, msg.str().c_str() );
		}

		client* c = get_client_attached_to_core_layer_interface(gateindex);
		if (c)
		{	//There is a client attached to that port
			if ( !c->is_waiting_for( msg->get_object_id() ) )
			{
				std::stringstream errmsg; 
				errmsg<<"I am node "<< getIndex()<<". I am sending a chunk of object "<< msg->get_object_id() <<
					" to the attached client of type "<< c->getModuleType() << 
					" that is not waiting for it. This is not necessarily an error, as this data could have been "
					<<" requested by the client and the client could have retrieved it before and now"
					<<" it may be fine and not wanting the data anymore. If it is the case, "<<
					"ignore this message ";
				debug_message(__FILE__, __LINE__, errmsg.str().c_str() );
			}

			if ( !c->is_active() )
			{
				std::stringstream msg; 
				msg<<"I am node "<< getIndex()<<". I am sending a data to the attached client "<<
					", that is not active, "<<
					" through port "<<gateindex<<". This was commanded in line "<< line_of_the_call;
				severe_error(__FILE__, __LINE__, msg.str().c_str() );
			}
		}

		content_distribution::get_repr_h()->check_representation_mask(msg->getChunk(), CCN_D );
		#endif
	//}CHECKS


	iface_stats[gateindex].slots_sent += msg->getSlotLength();

    int ret_value = send (msg, gatename, gateindex);
    ContentStore->after_sending_data(msg);
    return ret_value;
}

#ifdef SEVERE_DEBUG
	//		If there is a client attached to the specified interface, it will be returned. 
	//		Otherwise a null pointer will be returned
	client* core_layer::get_client_attached_to_core_layer_interface(int interface)
	{
		client *c;
		cModule* directly_connected_module = gate("face$o",interface)->getNextGate()->getOwnerModule();
		cModule* module_to_check;
		if (directly_connected_module == getParentModule() && 
			cModuleType::find("modules.node.node") == getParentModule()->getModuleType() 
		){
			// directly_connected_module is the node that contains this core_layer
			module_to_check = gate("face$o",interface)->getNextGate()->getNextGate()->getOwnerModule();
			c = (module_to_check->getModuleType()== cModuleType::find("modules.clients.client") )?
				dynamic_cast<client *> (module_to_check) : NULL;
		} else if (directly_connected_module->getModuleType() == cModuleType::find("modules.clients.ProactiveComponent") )
			c = dynamic_cast<client *> (directly_connected_module);
		else
			severe_error(__FILE__,__LINE__,"error in recognizing modules attached to faces");
		return c;
	}
#endif

//</aa>
