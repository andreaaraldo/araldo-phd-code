// Nice tutorial in http://www.boost.org/doc/libs/1_55_0/libs/graph/doc/quick_tour.html

#include <boost/config.hpp>
#include <iostream>                         // for std::cout
#include <utility>                          // for std::pair
#include <algorithm>                        // for std::for_each
#include <boost/utility.hpp>                // for boost::tie
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/graphviz.hpp>


using namespace boost;
using namespace std;

int main(int,char*[])
{
	// create a typedef for the Graph type
	typedef adjacency_list<vecS, vecS, undirectedS,
		no_property, property<edge_weight_t, float> > Graph;
	typedef graph_traits<Graph>::vertex_descriptor Vertex;

	// writing out the edges in the graph
	typedef std::pair<int, int> E;
	E edges[] = {E(1,2), E(1,11), E(2,11), E(10,11), E(2,3),
		E(3,4), E(4,5), E(5,6), E(6,7), E(4,8), E(7,8), E(3,9), 
		E(8,9), E(9,10)};

	const int num_edges = sizeof(edges)/sizeof(edges[0]);
	const int num_nodes = 11;
	float lambdas[num_edges]; // Lagrange multipliers
	int weights[num_edges];
	int weights_temp[num_edges];
	for (int j=0; j<num_edges; j++) {weights[j]=0; lambdas[j]=1;}

	float obj_size = 1;
	for (int j=0; j<num_edges; j++) {weights_temp[j] = weights[j]+obj_size*lambdas[j];}

    // declare a graph object
    Graph G(edges, edges + sizeof(edges) / sizeof(E), weights_temp, num_nodes);
	
	// vector for storing distance property
	std::vector<int> distance(num_nodes);
	Vertex source = vertex(1,G);
	dijkstra_shortest_paths(G, source, distance_map(&distance[0]));

	cout << "distances from start vertex:" << endl;
	graph_traits<Graph>::vertex_iterator vi;
	for(vi = vertices(G).first; vi != vertices(G).second; ++vi)
		cout << "distance(" << index(*vi) << ") = " 
              << distance[*vi] << endl;
	cout << endl;

    return 0;
}
