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
Vertex clients_[] = {5};
Vertex sources_[] = {8};
Vertex repositories_[] = {8};
E edges_[] = {E(1,2), E(1,0), E(2,0), E(10,0), E(2,3),
		E(3,4), E(4,5), E(5,6), E(6,7), E(4,8), E(7,8), E(3,9), 
		E(8,9), E(9,10)};
Weight weights[] = {1, 1, 1, 1, 1,
						1, 1, 1, 1, 1.01, 1, 1,
						1, 1};

Object num_objects = 3;
Quality num_qualities =2;


unsigned count_nodes(vector<E> edges)
{
	//Count the number of nodes
	// The max number of nodes is the num of edges +1
	set<int> nodes;
	for (int j=0; j < edges.size(); j++)
	{
		nodes.insert(edges[j].first); nodes.insert(edges[j].second);
	}
	int j=0;
	for (set<int>::iterator it=nodes.begin(); it!=nodes.end(); ++it, j++)
    	if(j!=*it){
			cout<<"Nodes should be numbered from 0 to "<<nodes.size()-1<<endl; exit(0);
		}
	return nodes.size();
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
/*
		ClientSourceDistanceMap client_distances;
		for (int j=0; j<clients.size(); j++)
		{
			Vertex client = vertex(clients[j],G);
			client_distances.emplace(std::make_pair(client,source), distances[client]);

			PathType path;
			Vertex v=client;
			for (Vertex u = predecessorMap[v]; u!=v; v=u, u=predecessorMap[v])
			{
				std::pair<Graph::edge_descriptor, bool> edgePair = boost::edge(u, v, G);
				Graph::edge_descriptor edge = edgePair.first;		 
				path.push_back( edge );
			}
		}
	return client_distances;
*/
}

void compute_shortest_paths	(const vector<Vertex>& sources, const vector<Vertex>& clients, Graph G,
	map<Vertex, vector<Vertex> >& out_predecessors_to_source,
	map<Vertex, vector<Weight> >& out_pair_distances)
{
	vector<Weight> distances(num_vertices(G));
	vector<Vertex> predecessors(num_vertices(G));

	for(unsigned s=0; s<sources.size(); s++)
	{
		compute_paths_from_source(sources[s], clients, G,
					distances, predecessors);
		out_predecessors_to_source.emplace(sources[s], predecessors);
		for(unsigned c=0; c<clients.size(); c++)
		{
			out_pair_distances.emplace( pair(sources[s],clients[c]), distances[clients[c]]);
		}
	}
}

// Returns the distance to the best repository
void find_the_best_repository(const vector<Vector>& repositories, 
		const map<Vertex, vector<Weight> >& distances_from_sources, Object o,
		map< pair<Vertex,Vertex>, Weight >& out_best_repo_map)
{
	unsigned repo_idx=0;
	do
	{
		Vertex repo = repositories[repo_idx];
		distances_from_sources[repo];
		repo_idx++;
	}while(repo_idx<repositories.size() )
}


int main(int,char*[])
{

	// writing out the edges in the graph
	vector<E> edges(edges_, edges_+sizeof(edges_)/sizeof(E) );
	vector<Vertex> clients(clients_, clients_+
		sizeof(clients_)/sizeof(Vertex) );
	vector<Vertex> sources(sources_, sources_+
		sizeof(sources_)/sizeof(Vertex) );
	vector<Vertex> repositories(repositories_, repositories_+
		sizeof(repositories_)/sizeof(Vertex) );
	
	unsigned num_nodes = count_nodes(edges);

    // declare a graph object
    Graph G(edges_, edges_ + sizeof(edges_)/sizeof(E), weights, num_nodes);

	map<Vertex, vector<Vertex> > predecessors_to_source; // The key is the source
	map< pair<Vertex,Vertex>,Weight > pair_distances; // The key is the source

	compute_shortest_paths(sources, clients, G, predecessors_to_source, pair_distances);

	ObjectMap obj_distribution;

	for(Object o=0; o<num_objects; o++)	
	{
		for(unsigned id_cli=0; id_cli < clients.size(); id_cli++)
		{
			Vertex client = clients[id_cli];
			for(Quality q=0; q<num_qualities; q++)
			{
				Vertex best_source = repositories[0];
				Weight best_distance = distances_from_sources[best_source][client];
				for ( FileCollection::iterator it = obj_distribution[o].begin(); 
					it != obj_distribution[o].end();
					++it
					)
				{
					it->
					cout<< "ciao"<<endl;
				}
			}
		}
	}
    return 0;
}
