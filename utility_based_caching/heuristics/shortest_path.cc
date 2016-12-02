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
Vertex ASes_with_users_[] = {5};
E edges_[] = {E(1,2), E(1,0), E(2,0), E(10,0), E(2,3),
		E(3,4), E(4,5), E(5,6), E(6,7), E(4,8), E(7,8), E(3,9), 
		E(8,9), E(9,10)};
Weight weights[] = {1, 1, 1, 1, 1,
						1, 1, 1, 1, 1.01, 1, 1,
						1, 1};


const int server_idx = 8;

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
ClientSourceDistanceMap compute_distances_from_source(
	Vertex source, vector<Vertex> ASes_with_users, Graph G)
{

	IndexMap indexMap = boost::get(boost::vertex_index, G);
	boost::property_map<Graph, boost::edge_weight_t>::type EdgeWeightMap = 
				get(boost::edge_weight_t(), G);

		// vector for storing distance property
		vector<Weight> distances(num_vertices(G));
		vector<Vertex> predecessors(num_vertices(G));
		PredecessorMap predecessorMap(&predecessors[0], indexMap);
		DistanceMap distanceMap(&distances[0], indexMap);
		dijkstra_shortest_paths(G, source, 
			distance_map(distanceMap).predecessor_map(predecessorMap) );

		ClientSourceDistanceMap client_distances;
		Weight cost=0;
		for (int j=0; j<ASes_with_users.size(); j++)
		{
			Vertex client = vertex(ASes_with_users[j],G);
			client_distances.emplace(std::make_pair(client,source), distances[client]);

			PathType path;
			Vertex v=client;
			for (Vertex u = predecessorMap[v]; u!=v; v=u, u=predecessorMap[v])
			{
				std::pair<Graph::edge_descriptor, bool> edgePair = boost::edge(u, v, G);
				Graph::edge_descriptor edge = edgePair.first;		 
				path.push_back( edge );
				cost += EdgeWeightMap[edge];
			}
		}
	return client_distances;
}


int main(int,char*[])
{

	// writing out the edges in the graph
	vector<E> edges(edges_, edges_+sizeof(edges_)/sizeof(E) );
	vector<Vertex> ASes_with_users(ASes_with_users_, ASes_with_users_+
		sizeof(ASes_with_users_)/sizeof(Vertex) );
	
	unsigned num_nodes = count_nodes(edges);
	cout << "count_nodes = "<< num_nodes <<endl;

    // declare a graph object
    Graph G(edges_, edges_ + sizeof(edges_)/sizeof(E), weights, num_nodes);

	ClientSourceDistanceMap client_source_distances = 
			compute_distances_from_source(vertex(server_idx,G), ASes_with_users, G);
	
    return 0;
}
