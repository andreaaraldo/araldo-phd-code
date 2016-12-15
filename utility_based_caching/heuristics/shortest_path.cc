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


using namespace boost;
using namespace std;

const float single_node_capacity = 10;
Vertex caches_[] = {5,4};
Vertex repositories_[] = {8};
E edges_[] = {E(1,2), E(1,11), E(2,11), E(10,11), E(2,3),
		E(3,4), E(4,5), E(5,6), E(6,7), E(4,8), E(7,8), E(3,9), 
		E(8,9), E(9,10)};

Weight init_w=1; // Initialization weight
Weight weights[] = {init_w, init_w, init_w, init_w, init_w,
						init_w, init_w, init_w, init_w, init_w, init_w, init_w,
						init_w, init_w};
Weight utilities[] = {1};
Size sizes[] = {1};
Quality qualities;


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


//} DATA STRUCTURES


void initialize_requests(RequestSet& requests)
{
	requests.emplace(pair<Vertex,Object>(1,1) , 10) ;
	requests.emplace(pair<Vertex,Object>(1,2) , 10) ;
}

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
		best.src=repo; best.distance=distance; best.q= best_q; best.utility=best_utility;
		out_best_repo_map.emplace(client, best );
	}

	cout<<"check"<<endl;
	for (MyMap< Vertex, OptimalClientValues >::iterator it=out_best_repo_map.begin();
		it != out_best_repo_map.end(); ++it
		)
	{
		Vertex client = it->first;
		OptimalClientValues best = it->second;
		cout<<client<<":"<<best.src<<":"<<best.distance<<":"<<unsigned(best.q)<<":"<<best.utility<<endl;
	}
}


Weight compute_benefit(const Incarnation& inc, const vector<Vertex> clients, const Graph& G,
		const IncarnationCollection& cached_incarnations, 
		const MyMap< Vertex, MyMap<Vertex,Weight > >& distances,
		const MyMap< Vertex, OptimalClientValues >& best_repo_map ,
		const BestSrcMap& best_cache_map
){
	Weight benefit=0;
	Object obj = inc.o;
	Vertex src_new = inc.src;
	Quality q_new = inc.q;

	// distances associates to each source a map associating to each client the distance to that source
	MyMap<Vertex,Weight> tmp_distances_to_incarnation = distances.at(src_new);
		
	for (vector<Vertex>::const_iterator it = clients.begin(); it != clients.end(); ++it)
	{
		Vertex cli = *it;
		Weight distance_new = tmp_distances_to_incarnation.at(cli);
		Weight u_new = utilities[q_new] - sizes[q_new] * distance_new;
		
		OptimalClientValues opt_val_to_repo = best_repo_map.at(cli);
		Weight u_repo = opt_val_to_repo.utility;
		Quality q_repo = opt_val_to_repo.q;


		Weight u_best;
		BestSrcMap::const_iterator bcp_it = best_cache_map.find(obj);
		if(bcp_it != best_cache_map.end() )
		{
			// Recall that if there is an entry in best_cache_map, it means that the cache location
			// pointed there is better than all the repos, i.e., it guarantess a higher utility
			MyMap<Vertex,OptimalClientValues> opt_cache_values_per_obj = bcp_it->second; 
			OptimalClientValues& opt_val_to_cache = opt_cache_values_per_obj.at(cli);
			u_best = opt_val_to_cache.utility;
		}else
		{
			// There is no good cache location, and thus the best utility we could get (before
			// considering the new incarnation) is provided by the best repo
			u_best = u_repo;
		}

		if (u_new > u_best)
		{
			Requests n = requests.at(pair<Vertex,Object>(cli,obj) );
			benefit += n * (u_new - u_best)/sizes[q_new];
		} // else the benefit is not incremented
	}
	return benefit;
}



int main(int,char*[])
{
	initialize_requests(requests);

	qualities = sizeof(utilities)/sizeof(Weight);
	//{ CHECK INPUT	
		if (qualities != sizeof(sizes)/sizeof(Size) )
			throw std::invalid_argument("Sizes are badly specified");
	//} CHECK INPUT	

	//{ INITIALIZE INPUT DATA STRUCTURE
	vector<E> edges(edges_, edges_+sizeof(edges_)/sizeof(E) );
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
	//} INITIALIZE INPUT DATA STRUCTURE
	
	unsigned num_nodes = count_nodes(edges);

    // declare a graph object
    Graph G(edges_, edges_ + sizeof(edges_)/sizeof(E), weights, num_nodes);

	fill_distances(sources, clients, G, predecessors_to_source, distances);

	fill_best_repo_map(repositories, clients, distances, best_repo_map);

	IncarnationCollection cached_incarnations; // It is initially empty
	IncarnationCollection unused_incarnations;
	for(vector<Object>::iterator obj_it = objects.begin(); obj_it != objects.end(); ++obj_it)
	for(vector<Vertex>::iterator cache_it = caches.begin(); cache_it != caches.end(); ++cache_it)
	for(Quality q=0; q<qualities; q++)
	{
		Incarnation inc; inc.o = *obj_it; inc.q = q; inc.src=*cache_it;
		unused_incarnations.push_back(inc);
	}
	cout<<"Unused Incarnations"<<endl;
	for (IncarnationCollection::iterator it=unused_incarnations.begin(); 
			it!=unused_incarnations.end(); ++it)
	{
		Incarnation inc = *it;
		Weight b= compute_benefit(inc, clients, G,
			cached_incarnations, distances, best_repo_map, best_cache_map);
		cout<<*it<<":"<<b<<endl;
	}


	//////////////////////////////////////////////////
	//////// UNUSED INCARNATIONS MUST BE ORDERED /////
	//////////////////////////////////////////////////


    return 0;
}
