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
Vertex caches_[] = {5};
Vertex repositories_[] = {1,8};
E edges_[] = {E(1,2), E(1,11), E(2,11), E(10,11), E(2,3),
		E(3,4), E(4,5), E(5,6), E(6,7), E(4,8), E(7,8), E(3,9), 
		E(8,9), E(9,10)};

Weight init_w=0.0001; // Initialization weight
Weight weights[] = {100*init_w, init_w, 100*init_w, init_w, 100*init_w,
						init_w, init_w, init_w, init_w, init_w, init_w, init_w,
						init_w, init_w};
Weight utilities[] = {0.67, 0.80};
Size sizes[] = {300,700};
Quality qualities;

Object num_objects = 3;

void initialize_requests(RequestSet& requests)
{
	requests.emplace(pair<Vertex,Object>(5,1) , 10) ;
	requests.emplace(pair<Vertex,Object>(5,2) , 5) ;
	requests.emplace(pair<Vertex,Object>(5,3) , 0) ;
	requests.emplace(pair<Vertex,Object>(2,3) , 0) ;
	requests.emplace(pair<Vertex,Object>(8,3) , 1) ;
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
	Vertex source, vector<Vertex> clients, Graph G,
	vector<Weight>& out_distances, vector<Vertex>& out_predecessors)
{

	IndexMap indexMap = boost::get(boost::vertex_index, G);
	boost::property_map<Graph, boost::edge_weight_t>::type EdgeWeightMap = 
				get(boost::edge_weight_t(), G);


		//it associates to each node its next node to the source
		PredecessorMap predecessorMap(&out_predecessors[0], indexMap);
		DistanceMap distanceMap(&out_distances[0], indexMap);
		dijkstra_shortest_paths(G, source, 
			distance_map(distanceMap).predecessor_map(predecessorMap) );

}

void compute_shortest_paths	(const vector<Vertex>& sources, const vector<Vertex>& clients, Graph G,
	MyMap<Vertex, vector<Vertex> >& out_predecessors_to_source,
	MyMap< pair<Vertex,Vertex>,Weight >& out_pair_distances // The key is the (source,client) pair
	)
{
	vector<Weight> distances(num_vertices(G));
	vector<Vertex> predecessors(num_vertices(G));

	for(unsigned s=0; s<sources.size(); s++)
	{
		compute_paths_from_source(sources[s], clients, G,
					distances, predecessors);
		out_predecessors_to_source[sources[s] ] = predecessors;
		for(unsigned c=0; c<clients.size(); c++)
		{
			out_pair_distances[ pair<Vertex,Vertex>(sources[s],clients[c])] = 
				distances[clients[c]];
		}
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
		const MyMap< pair<Vertex,Vertex>,Weight >& pair_distances, // The key is the 
																// (source,client) pair,
		MyMap< Vertex, OptimalClientValues >& out_best_repo_map
		)
{
	// Find the closest repo per each client
	MyMap<Vertex, pair<Vertex, Weight> > closest_repo;

	for(vector<Vertex>::const_iterator repo_it=repositories.begin(); 
		repo_it != repositories.end(); ++repo_it
	)
	for(vector<Vertex>::const_iterator cli_it=clients.begin(); 
		cli_it != clients.end(); ++cli_it
	){
		Vertex new_repo = *repo_it;
		Vertex client = *cli_it;
		Weight new_distance = pair_distances.at(pair<Vertex,Vertex>(new_repo,client) );

		pair<MyMap<Vertex, pair<Vertex, Weight> >::iterator,bool> inserted = closest_repo.emplace( 
			client,pair<Vertex, Weight>(new_repo,new_distance)
			);
		if (inserted.second == false)
		{
			// The new values have not been inserted. We check if they are better then the older
			MyMap<Vertex, pair<Vertex, Weight> >::iterator old_pair = inserted.first;
			Weight old_distance = (old_pair->second).second;
			if (new_distance < old_distance)
			{
				(old_pair->second).first = new_repo;
				(old_pair->second).second = new_distance;
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
		best.repo=repo; best.distance=distance; best.q= best_q; best.utility=best_utility;
		out_best_repo_map.emplace(client, best );
	}

	cout<<"check"<<endl;
	for (MyMap< Vertex, OptimalClientValues >::iterator it=out_best_repo_map.begin();
		it != out_best_repo_map.end(); ++it
		)
	{
		Vertex client = it->first;
		OptimalClientValues best = it->second;
		cout<<client<<":"<<best.repo<<":"<<best.distance<<":"<<unsigned(best.q)<<":"<<best.utility<<endl;
	}
}



int main(int,char*[])
{
	RequestSet requests;
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

	MyMap<Vertex, vector<Vertex> > predecessors_to_source; // The key is the source
	MyMap< pair<Vertex,Vertex>,Weight > pair_distances; // The key is the (source,client) pair

	compute_shortest_paths(sources, clients, G, predecessors_to_source, pair_distances);

	MyMap< Vertex, OptimalClientValues > best_repo_map;
	fill_best_repo_map(repositories, clients, pair_distances, best_repo_map);

	IncarnationCollection unused_incarnations;
	for(vector<Object>::iterator obj_it = objects.begin(); obj_it != objects.end(); ++obj_it)
	for(vector<Vertex>::iterator cache_it = caches.begin(); cache_it != caches.end(); ++cache_it)
	for(Quality q=0; q<qualities; q++)
	{
		Incarnation inc; inc.o = *obj_it; inc.q = q; inc.v=*cache_it;
		unused_incarnations.push_back(inc);
	}
	cout<<"Unused Incarnations"<<endl;
	for (IncarnationCollection::iterator it=unused_incarnations.begin(); 
			it!=unused_incarnations.end(); ++it)
		cout<<*it<<endl;
	compute_benefit();

	//////////////////////////////////////////////////
	//////// UNUSED INCARNATIONS MUST BE ORDERED /////
	//////////////////////////////////////////////////


    return 0;
}
