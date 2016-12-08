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


#ifndef SHORTEST_PATH_H_
#define SHORTEST_PATH_H_

using namespace boost;

//{ TYPES
	// create a typedef for the Graph type
	typedef float Weight;
	typedef adjacency_list<vecS, vecS, undirectedS,
		no_property, property<edge_weight_t, float> > Graph;
	typedef graph_traits<Graph>::vertex_descriptor Vertex;
	typedef boost::property_map < Graph, boost::vertex_index_t >::type IndexMap;
	typedef boost::iterator_property_map < Vertex*, IndexMap, Vertex, Vertex& > PredecessorMap;
	typedef boost::iterator_property_map < Weight*, IndexMap, Weight, Weight& > DistanceMap;
	typedef std::vector<Graph::edge_descriptor> PathType;
	typedef std::pair<int, int> E;

	typedef uint8_t Quality;
	typedef unsigned Object;
	typedef std::list<std::pair<Quality,Vertex> > FileCollection;
	typedef std::map<Object, FileCollection > ObjectMap;
//} TYPES
#endif
