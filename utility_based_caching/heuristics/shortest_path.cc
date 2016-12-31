// Nice tutorial in http://www.boost.org/doc/libs/1_55_0/libs/graph/doc/quick_tour.html

#include <boost/config.hpp>
#include <iostream>                         // for std::cout
#include <utility>                          // for std::pair
#include <algorithm>                        // for std::for_each
#include <boost/utility.hpp>                // for boost::tie
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/graph_traits.hpp>
#include <boost/graph/dijkstra_shortest_paths.hpp>
#include <boost/property_map/property_map.hpp>
#include <boost/graph/graphviz.hpp>
#include "shortest_path.h"
#include <cmath> // for sqrt()

#define SEVERE_DEBUG


using namespace boost;
using namespace std;

Vertex caches_[] = {2,9,4};
Vertex repositories_[] = {8};
E edges_[] = {E(1,2), E(1,11), E(2,11), E(10,11), E(2,3),
		E(3,4), E(4,5), E(5,6), E(6,7), E(4,8), E(7,8), E(3,9), 
		E(8,9), E(9,10)};

Size link_capacity = 490000; // In Kbps
Weight init_w=0.000070; // Initialization weight
Weight weights[] = {init_w, init_w, init_w, init_w, init_w,
						init_w, init_w, init_w, init_w, init_w, init_w, init_w,
						init_w, init_w};
Weight utilities[] = {0.6,1};
Size sizes[] = {1500,3500}; // In Kbps
Size single_storage=1; //As a multiple of the highest quality size
Quality qualities;

// Returns the total number of requests
Requests initialize_requests(RequestSet& requests)
{
	requests.emplace(pair<Vertex,Object>(1,1) , 100) ;
	requests.emplace(pair<Vertex,Object>(1,2) , 50) ;
	requests.emplace(pair<Vertex,Object>(1,3) , 1) ;
	requests.emplace(pair<Vertex,Object>(5,1) , 100) ;
	requests.emplace(pair<Vertex,Object>(5,2) , 50) ;
	requests.emplace(pair<Vertex,Object>(5,3) , 1) ;

	Requests tot_requests = 0;
	for (RequestSet::iterator it = requests.begin(); it!=requests.end(); ++it)
	{
		tot_requests += it->second;
	}
	return tot_requests;
}



//{ DATA STRUCTURES

	RequestSet requests;


	// Associates to each source a vector, having in the i-th position the predecessor of 
	// the i-th node toward that source
	MyMap<Vertex, vector<Vertex> > predecessors_to_source; 

	// Associates to each source a map associating to each client the distance to that source
	MyMap< Vertex, MyMap<Vertex,Weight > > distances;

	// Associates to each client, the best repository and the corresponding optimal information
	MyMap< Vertex, OptimalClientValues > best_repo_map;

	// Associates to each object a map associating to each client the set of its optimal values
	// to retrieve that object
	BestSrcMap best_cache_map;

	IncarnationCollection unused_incarnations;

	MyMap<Vertex,Size> cache_occupancy;

	Size max_size;

	EdgeLoads edge_loads;
//} DATA STRUCTURES



unsigned count_nodes(vector<E> edges)
{
	//Count the number of nodes
	// The max number of nodes is the num of edges +1
	set<int> nodes;
	for (int j=0; j < edges.size(); j++)
	{
		nodes.insert(edges[j].first); nodes.insert(edges[j].second);
	}
	return nodes.size();
}

void fill_clients_and_objects(const RequestSet& requests, 
		vector<Vertex>& out_clients, vector<Object>& out_objects)
{
	set<Vertex> client_set;
	set<Object> object_set;
	for (RequestSet::const_iterator it = requests.begin(); it!=requests.end(); ++it)
	{
		Requests num_req = (it->first).second;
		if(num_req>0)
		{
			Vertex client = (it->first).first;
			Object obj =  (it->first).second;
			client_set.insert( client );
			object_set.insert( obj );
		}
	}
	std::copy(client_set.begin(), client_set.end(), std::back_inserter(out_clients) );
	std::copy(object_set.begin(), object_set.end(), std::back_inserter(out_objects) );
}


// Returns the distance between each client and the source
void compute_paths_from_source(
	Vertex source, const vector<Vertex>& clients, Graph& G,
	vector<Weight>& out_distances_from_single_source, vector<Vertex>& out_predecessors
){

	IndexMap indexMap = boost::get(boost::vertex_index, G);
	property_map<Graph, edge_weight_t>::type EdgeWeightMap = get(edge_weight, G);


		//it associates to each node its next node to the source
		PredecessorMap predecessorMap(&out_predecessors[0], indexMap);
		DistanceMap distanceMap(&out_distances_from_single_source[0], indexMap);
		dijkstra_shortest_paths(G, source, 
			distance_map(distanceMap).predecessor_map(predecessorMap) );

}

void fill_distances	(const vector<Vertex>& sources, const vector<Vertex>& clients, Graph G,
	MyMap<Vertex, vector<Vertex> >& out_predecessors_to_sources,
	MyMap< Vertex, MyMap<Vertex,Weight> >& out_distances
	)
{
	vector<Weight> tmp_distances_from_single_source(num_vertices(G));
	vector<Vertex> tmp_predecessors(num_vertices(G));

	for(vector<Vertex>::const_iterator it_src = sources.begin(); 
			it_src != sources.end(); ++it_src
	){
		Vertex src = *it_src;
		compute_paths_from_source(src, clients, G,
					tmp_distances_from_single_source, tmp_predecessors);
		out_predecessors_to_sources[ src ] = tmp_predecessors;
		MyMap<Vertex, Weight> tmp_distances_to_src_map;
		for(vector<Vertex>::const_iterator it_cli = clients.begin(); 
				it_cli != clients.end(); ++it_cli
		){
			Vertex cli = *it_cli;
			tmp_distances_to_src_map.emplace(cli, tmp_distances_from_single_source[cli] );
		}
		out_distances.emplace(src, tmp_distances_to_src_map);
	}
}

/*
 * Returns the distance to the best repository.
 * Each repository is assumed to hold all the objects at all the quality levels.
 * out_best_repo_map will associate to each client a pair containing the best repo and the distance to reach it.
 */
void fill_best_repo_map(
		const vector<Vertex>& repositories, 
		const vector<Vertex>& clients,
		const MyMap< Vertex, MyMap<Vertex,Weight > >& distances,// The key is the 
																// source. The value is a map
																// associating to each client
																// its distance from the source
		MyMap< Vertex, OptimalClientValues >& out_best_repo_map
		)
{
	// Find the closest repo per each client
	MyMap<Vertex, pair<Vertex, Weight> > closest_repo;

	for(vector<Vertex>::const_iterator repo_it=repositories.begin(); 
		repo_it != repositories.end(); ++repo_it
	)
	{
		Vertex new_repo = *repo_it;
		MyMap<Vertex,Weight> distances_from_the_repo = distances.at(new_repo);
		for(vector<Vertex>::const_iterator cli_it=clients.begin(); 
			cli_it != clients.end(); ++cli_it
		){
			Vertex client = *cli_it;
			Weight new_distance = distances_from_the_repo.at(client);

			pair<MyMap<Vertex, pair<Vertex, Weight> >::iterator,bool> inserted = 
				closest_repo.emplace( 
					client,pair<Vertex, Weight>(new_repo,new_distance)
				);

			if (inserted.second == false)
			{
				// The new values have not been inserted. This means that there was an old value
				// already stored.
				MyMap<Vertex, pair<Vertex, Weight> >::iterator old_pair = inserted.first;
				Weight old_distance = (old_pair->second).second;
				if (new_distance < old_distance)
				{
					(old_pair->second).first = new_repo;
					(old_pair->second).second = new_distance;
				}
			}
		}
	}

	// Now, for each client we compute the optimal quality at which it has to download its requested objects
	for (MyMap<Vertex, pair<Vertex, Weight> >::iterator it = closest_repo.begin();
		it != closest_repo.end();
		++it)
	{
		Vertex client = it->first;
		Vertex repo = (it->second).first;
		Weight distance = (it->second).second;
		Quality best_q;
		Weight best_utility;
		for (Quality q=0; q<qualities; q++)
		{
			Weight new_utility = utilities[q] - sizes[q] * distance;
			if (q==0 || new_utility > best_utility)
			{
				best_q = q; best_utility = new_utility;
			}
		}
		OptimalClientValues best;
		best.src=repo; best.distance=distance; best.q= best_q; best.per_req_utility=best_utility;
		out_best_repo_map.emplace(client, best );
	}

	cout<<"cli-repo:"<<endl;
	for (MyMap< Vertex, OptimalClientValues >::iterator it=out_best_repo_map.begin();
		it != out_best_repo_map.end(); ++it
		)
	{
		Vertex client = it->first;
		OptimalClientValues best = it->second;
		cout<<client<<":"<<best.src<<":"<<best.distance<<":"<<
				unsigned(best.q)<<":"<<best.per_req_utility<<endl;
	}
}


Weight compute_benefit(Incarnation& inc, const vector<Vertex> clients, const Graph& G,
		const MyMap< Vertex, MyMap<Vertex,Weight > >& distances,
		const MyMap< Vertex, OptimalClientValues >& best_repo_map ,
		const BestSrcMap& best_cache_map, 
		const MyMap<Vertex,Size>& cache_occupancy,
		vector<Vertex>& out_potential_additional_clients
){
	Weight benefit=0;
	Object obj = inc.o;
	Vertex src_new = inc.src;
	Quality q_new = inc.q;
	Size size_new = sizes[q_new];
	
	if ( cache_occupancy.at(src_new) + size_new <= single_storage * max_size)
	{	// We have space to place this incarnation and the benefit could be > 0

		// distances associates to each source a map associating to each client the 
		// distance to that source
		MyMap<Vertex,Weight> tmp_distances_to_incarnation = distances.at(src_new);
		
		for (vector<Vertex>::const_iterator it = clients.begin(); it != clients.end(); ++it)
		{
			Vertex cli = *it;
			Weight distance_new = tmp_distances_to_incarnation.at(cli);
			Weight u_new = utilities[q_new] - sizes[q_new] * distance_new;
		
			OptimalClientValues opt_val_to_repo = best_repo_map.at(cli);
			Weight u_repo = opt_val_to_repo.per_req_utility;
			Quality q_repo = opt_val_to_repo.q;

			Weight u_best=u_repo;
			BestSrcMap::const_iterator bcp_it = best_cache_map.find(obj);
			if(bcp_it != best_cache_map.end() )
			{
				// Recall that if there is an entry in best_cache_map, it means that the cache 
				// location pointed there is better than all the repos, i.e., it 
				// guarantess a higher utility
				MyMap<Vertex,OptimalClientValues> opt_cache_values_per_obj = bcp_it->second;
				MyMap<Vertex,OptimalClientValues>::iterator ocv_it = 
						opt_cache_values_per_obj.find(cli);
				if (ocv_it != opt_cache_values_per_obj.end() )
				{
					OptimalClientValues& opt_val_to_cache = opt_cache_values_per_obj.at(cli);
					u_best = opt_val_to_cache.per_req_utility;
				} // else there is no cache location that is associated to that object and 
				  // that client
			}// else There is no good cache location, and thus the best utility we could 
			 // get (before considering the new incarnation) is provided by the best repo

			Requests n = requests.at(pair<Vertex,Object>(cli,obj) );
			if (u_new > u_best && n>0)
			{
				benefit += n * (u_new - u_best)/sizes[q_new];
				out_potential_additional_clients.push_back(cli);
			} // else the benefit is not incremented
		}
	} 	//else benefit remains 0, in order to avoid to insert this element, since there is no room
		// for it

	#ifdef SEVERE_DEBUG
	if (benefit>0 && out_potential_additional_clients.size()==0 )
	{
		stringstream os; os<<"Incarnation "<<inc<<" has benefit "<< benefit << " but no clients"<<
			" are affected";
		std::invalid_argument(os.str().c_str() );
	}
	#endif

	return benefit;
}

void print_collection(const IncarnationCollection& ic )
{
	cout<<"Incarnations"<<endl;
	for (IncarnationCollection::const_iterator it=ic.begin(); 
			it!=ic.end(); ++it)
	{
		Incarnation inc = *it;
		cout<<*it<<":"<<endl;
	}
}

void print_occupancy(const MyMap<Vertex,Size>& cache_occupancy )
{
	cout<<"Occupancy"<<endl;
	for (MyMap<Vertex,Size>::const_iterator it=cache_occupancy.begin(); 
			it!=cache_occupancy.end(); ++it)
	{
		Vertex cache = it->first;
		Size s = it->second;
		cout<<cache<<":"<<s<<"----";
	}
	cout<<endl;
}


Weight compute_per_req_utility(const Incarnation& inc, Vertex cli)
{
	Weight d = distances.at(inc.src).at(cli);
	return utilities[inc.q] - sizes[inc.q] * d;
}

void add_load(EdgeLoads& loads, const E e, const Weight load)
{
	throw invalid_argument("Implement this");
}

void update_load(EdgeLoads& edge_loads, 
	const Graph& G, const MyMap<Vertex, vector<Vertex> >& predecessors_to_source, 
	const Vertex src, const Vertex cli, const Weight load
){
	// Associates to each source a vector, having in the i-th position the predecessor of 
	// the i-th node toward that source
	const vector<Vertex> path = predecessors_to_source.at(src);
	cout << "Path from client " << cli << " to source "<< src<<": ";
	// Iteration through the path inspired by http://stackoverflow.com/a/12676435
	graph_traits< Graph >::vertex_descriptor current;
	for (current=cli; current!= src; current =  path[current] )
	{
		EdgeDescriptor e = edge(current,path[current],G).first;
		cout<<e<<"-";
		Weight old_load = 0;
		EdgeLoads::iterator it = edge_loads.find(e) ;
		if (it != edge_loads.end() )
			old_load = it->second;
		edge_loads[e] = old_load + load;
	}
	cout<<endl;
}

void print_edge_loads(const EdgeLoads& edge_loads)
{
	for (EdgeLoads::const_iterator it = edge_loads.begin(); it!=edge_loads.end() ; ++it)
	{
		cout<< it->first << ":" << it->second << " ";
	}
	cout <<endl;
}

// Return the average pure utility
Weight compute_edge_loads_and_pure_utility(EdgeLoads& edge_loads, 
	const Graph& G,
	const MyMap<Vertex, vector<Vertex> >& predecessors_to_source, 
	const vector<E>& edges, 
	const vector<Vertex>& clients,
	const MyMap< Vertex, OptimalClientValues >& best_repo_map, 
	const BestSrcMap& best_cache_map
){
	Weight tot_pure_utility=0;
	edge_loads.clear();
	cout<<"best_cache_map"<<endl;
	for (BestSrcMap::const_iterator it = best_cache_map.begin();
		it != best_cache_map.end(); ++it
	){
		Object o = it->first;
		for (vector<Vertex>::const_iterator cli_it=clients.begin(); 
			cli_it!=clients.end(); ++cli_it
		){
			OptimalClientValues ocv;
			Vertex cli = *cli_it;
			MyMap<Vertex,OptimalClientValues>::const_iterator ocv_it = (it->second).find(cli);
			if (ocv_it != (it->second).end() )
			{
				ocv = ocv_it->second;
				#ifdef SEVERE_DEBUG
				OptimalClientValues repo_ocv = best_repo_map.at(cli);
				if (repo_ocv.per_req_utility > ocv.per_req_utility)
				{
					stringstream os; os<<"Client "<<cli<<" downloads obj "<<o<<" from cache "<<
						ocv.src<<" with an utility "<<ocv.per_req_utility<<
						" but if it downloaded from repository the utility would be "<<
						repo_ocv.per_req_utility;
					throw std::invalid_argument(os.str().c_str() );
				}
				#endif
			}else{
				// the object is served by the best repository
				ocv = best_repo_map.at(cli);
			}
			Quality q = ocv.q;
			Vertex src = ocv.src;
			Requests n = requests.at(pair<Vertex,Object>(cli,o) );
			Weight load = n * sizes[q];
			tot_pure_utility += utilities[q] * n;
			update_load(edge_loads, G, predecessors_to_source, src, cli, load );
			
			cout<<"Object "<<o<<" is served to client "<<cli<<" through "<<ocv<<endl;
		}
	}
	return tot_pure_utility;
}

// Returns the tot_pure_utility
Weight greedy(EdgeLoads& edge_loads, vector<E>& edges, Graph& G)
{

	qualities = sizeof(utilities)/sizeof(Weight);
	//{ CHECK INPUT	
		if (qualities != sizeof(sizes)/sizeof(Size) )
			throw std::invalid_argument("Sizes are badly specified");
	//} CHECK INPUT	

	//{ INITIALIZE INPUT DATA STRUCTURE
	vector<Vertex> caches(caches_, caches_+
		sizeof(caches_)/sizeof(Vertex) );
	vector<Vertex> repositories(repositories_, repositories_+
		sizeof(repositories_)/sizeof(Vertex) );
	vector<Vertex> sources;
	sources.reserve(caches.size()+repositories.size() );
	sources.insert(sources.end(), caches.begin(), caches.end()); 
	sources.insert(sources.end(), repositories.begin(), repositories.end());
	vector<Vertex> clients;
	vector<Object> objects;
	fill_clients_and_objects(requests,clients,objects);
	
	max_size=0; for (const Size& s: sizes) if (s>max_size) max_size=s;
	//} INITIALIZE INPUT DATA STRUCTURE
	

	fill_distances(sources, clients, G, predecessors_to_source, distances);

	fill_best_repo_map(repositories, clients, distances, best_repo_map);

	for (vector<Vertex>::iterator it=caches.begin(); it!= caches.end(); ++it)
	{	Vertex cache = *it; cache_occupancy.emplace(cache,0);
	}

	//{ INITIALIZE INCARNATIONS
	cout << "Initializing incarnations"<<endl;
	for(vector<Object>::iterator obj_it = objects.begin(); obj_it != objects.end(); ++obj_it)
	for(vector<Vertex>::iterator cache_it = caches.begin(); cache_it != caches.end(); ++cache_it)
	for(Quality q=0; q<qualities; q++)
	{
		Incarnation inc; inc.o = *obj_it; inc.q = q; inc.src=*cache_it;
		vector<Vertex> potential_additional_clients; // I am not interested in this for the
															// time being
		Weight b= compute_benefit(inc, clients, G, distances, best_repo_map, 
			best_cache_map, cache_occupancy, potential_additional_clients);
		inc.benefit=b;
		cout<<inc<<endl;
		if (inc.benefit > 0)
			unused_incarnations.push_back(inc);
		// else it is not worth considering it
	}
	unused_incarnations.sort(compare_incarnations);
	print_occupancy(cache_occupancy);
	print_collection(unused_incarnations);
	//} INITIALIZE INCARNATIONS



	while (unused_incarnations.size()>0)
	{
		Incarnation best_inc = unused_incarnations.front();
		unused_incarnations.pop_front();

		#ifdef SEVERE_DEBUG
		cout<< "Selected incarnation "<<best_inc<<endl;
		for (MyMap<Vertex,Size>::const_iterator it=cache_occupancy.begin(); 
			it!=cache_occupancy.end(); ++it)
		{
			Vertex cache = it->first;
			Size s = it->second;
			if (s>single_storage*max_size)
			{
				char msg[200];
				sprintf(msg,"Storage constraints not verified:single_storage=%g; \
						cache %lu has %g of space occupied",
					single_storage, cache, s);
				throw std::invalid_argument(msg);
			}
		}
		#endif

		//{ UPDATE DATA AFTER SELECTION
			// I retrieve the clients that experience an improvement from the addition of best_inc
			// since only them change the associated source
			vector<Vertex> changing_clients;
			Weight b= compute_benefit(best_inc, clients, G, distances, best_repo_map, 
				best_cache_map, cache_occupancy, changing_clients);

			#ifdef SEVERE_DEBUG
			if (changing_clients.size()==0)
				throw std::invalid_argument("Storing last incarnation seems not to influence any\
					client, and thus is useless");
			#endif

			cout<<"changing clients:";
			// Update best_cache_map
			for(vector<Vertex>::iterator cli_it = changing_clients.begin(); 
				cli_it != changing_clients.end(); ++cli_it
			){
				Vertex cli = *cli_it;
				OptimalClientValues new_opt_val_to_cache;
				new_opt_val_to_cache.src = best_inc.src;
				new_opt_val_to_cache.distance = distances.at(best_inc.src).at(cli);
				new_opt_val_to_cache.q = best_inc.q;
				new_opt_val_to_cache.per_req_utility = compute_per_req_utility(best_inc, cli);
				best_cache_map[best_inc.o][cli] = new_opt_val_to_cache;
				cout<<cli<<":";
			}
			cout<<endl;

			//{ RECOMPUTE THE BENEFITS
			cache_occupancy[best_inc.src] = cache_occupancy[best_inc.src] + sizes[best_inc.q];

			for (IncarnationCollection::iterator inc_c_it = unused_incarnations.begin();
				inc_c_it != unused_incarnations.end(); ++inc_c_it
			)
			{
				Incarnation& inc = *inc_c_it;
				inc.benefit = compute_benefit(inc, clients, G, distances, best_repo_map, 
					best_cache_map, cache_occupancy, changing_clients);
			}
			//} RECOMPUTE THE BENEFITS
			
			unused_incarnations.sort(compare_incarnations);
			//std::sort(unused_incarnations.rbegin(), unused_incarnations.rend() );

			print_occupancy(cache_occupancy);
			print_collection(unused_incarnations);

			//{ PURGE USELESS INCARNATIONS
			// At the end we find all the zero-benefit incarnations
			Weight worst_benefit = unused_incarnations.back().benefit;
			while (worst_benefit == 0)
			{
				unused_incarnations.pop_back();
				if (unused_incarnations.size()>0)
					worst_benefit = unused_incarnations.back().benefit;
				else worst_benefit = 1; // Just to get out of the while
			}
			//} PURGE USELESS INCARNATIONS
		//{ UPDATE DATA AFTER SELECTION

	}

	Weight tot_pure_utility = compute_edge_loads_and_pure_utility(edge_loads, G,
			predecessors_to_source, edges, 
			clients, best_repo_map, best_cache_map);
	return tot_pure_utility;
}

int main(int,char*[])
{
	Requests tot_requests = initialize_requests(requests);
	

	//{ INITIALIZE INPUT DATA STRUCTURE
	vector<E> edges(edges_, edges_+sizeof(edges_)/sizeof(E) );
	//} INITIALIZE INPUT DATA STRUCTURE

	Weight tot_pure_utility;
	for (unsigned k=1; k<=200; k++)
	{
		unsigned num_nodes = count_nodes(edges);
		Graph G(edges_, edges_ + sizeof(edges_)/sizeof(E), weights, num_nodes);

		tot_pure_utility = greedy(edge_loads, edges, G);
		Weight tot_brut_utility = tot_pure_utility;
		print_edge_loads(edge_loads);
		
		// Compute the violations
		Weight violations[edges.size()];
		Weight norm_squared=0;
		for (unsigned eid=0; eid<edges.size(); eid++)
		{
			EdgeDescriptor e = edge(edges[eid].first, edges[eid].second ,G).first;
			violations[eid] = edge_loads[e] - link_capacity;
			norm_squared += violations[eid]*violations[eid];
			tot_brut_utility -=  weights[eid] * violations[eid];
			cout<< "violation on "<< e <<" = "<< violations[eid] <<endl;
		}

		float big_const = 100;
		float step =big_const * init_w / ( big_const+k * sqrt(norm_squared ) );
		for (unsigned eid=0; eid<edges.size(); eid++)
			weights[eid] = weights[eid] + step * violations[eid] > 0 ? 
							weights[eid] + step * violations[eid] :0;


		cout<<"New weights: "<<endl;
		for (unsigned eid=0; eid<edges.size(); eid++)
			cout << weights[eid] <<" ";
		cout <<endl;

		cout<<"tot_requests="<<tot_requests<<endl;
		cout<<"avg tot_brut_utility="<<tot_brut_utility/tot_requests<<endl;
	}
	return 0;
}
