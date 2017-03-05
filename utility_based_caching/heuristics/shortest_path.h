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
#include <unordered_map>
#include <tuple>



#ifndef SHORTEST_PATH_H_
#define SHORTEST_PATH_H_

using namespace boost;

//{ TYPES
	enum input_type{automatic, direct};
	enum serving_type{cache, repo, no};


	// create a typedef for the Graph type
	typedef double Weight;
	Weight WEIGHT_MAX = std::numeric_limits<Weight>::max();

	typedef adjacency_list<vecS, vecS, undirectedS,
		no_property, property<edge_weight_t, double> > Graph;
	typedef graph_traits<Graph>::vertex_descriptor Vertex;
	typedef boost::property_map < Graph, boost::vertex_index_t >::type IndexMap;
	typedef boost::iterator_property_map < Vertex*, IndexMap, Vertex, Vertex& > PredecessorMap;
	typedef boost::iterator_property_map < Weight*, IndexMap, Weight, Weight& > DistanceMap;
	typedef std::vector<Graph::edge_descriptor> PathType;
	typedef std::pair<int, int> E;

	template<typename T1, typename T2> using MyMap = std::map<T1,T2>;
	typedef uint8_t Quality;
	typedef unsigned Object;
	typedef unsigned Requests;
	typedef double Size;

	struct IncarnationStruct
	{	
		Object o; Quality q; Vertex src; Weight benefit; 
		bool valid; // True only if the benefit has been computed
		IncarnationStruct() : benefit(0), valid(false) {};
	};
	typedef IncarnationStruct Incarnation;
	std::ostream& operator<<(std::ostream& os, const Incarnation& inc)  
	{  
		os << inc.o << ':' << unsigned(inc.q) << ':' << inc.src;
		if(inc.valid) os<<":"<<inc.benefit;  
		return os;  
	} 
	bool compare_incarnations(const Incarnation& inc1, const Incarnation& inc2)	
	{
		return (inc1.benefit > inc2.benefit);
	}

	typedef graph_traits < Graph >::edge_descriptor EdgeDescriptor;

	typedef std::list< Incarnation > IncarnationCollection; 
	typedef std::unordered_map<Object, IncarnationCollection > ObjectMap;
	typedef MyMap< std::pair<Vertex,Object> , Requests> RequestSet;
	typedef struct{
		Vertex src; Weight distance; Quality q; Weight per_req_gross_utility;
	} OptimalClientValues;
	typedef MyMap<Object, MyMap<Vertex,OptimalClientValues> > BestSrcMap;
	std::ostream& operator<<(std::ostream& os, const OptimalClientValues& ocv)  
	{  
		os<<"q:"<<unsigned(ocv.q) << "-src:" << ocv.src<<"-d:"<<ocv.distance<<
				"-u:"<<ocv.per_req_gross_utility;
	} 
	typedef std::map<EdgeDescriptor,Weight> EdgeValues;

//} TYPES

	template<typename A, typename B>
	std::pair<B,A> flip_pair(const std::pair<A,B> &p)
	{
		return std::pair<B,A>(p.second, p.first);
	}

	template<typename A, typename B>
	std::multimap<B,A> flip_map(const std::map<A,B> &src)
	{
		std::multimap<B,A> dst;
		std::transform(src.begin(), src.end(), std::inserter(dst, dst.begin()), 
		               flip_pair<A,B>);
		return dst;
	}
#endif
