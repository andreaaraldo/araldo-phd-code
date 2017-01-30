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
#include "zipf.h"
#include <fstream>
#include <string>

#include <climits>
#include <boost/tokenizer.hpp>

//#define SEVERE_DEBUG
//#define VERBOSE


using namespace boost;
using namespace std;

Vertex caches_[] = {1,2,3,4,5,6,7,8,9,10,11};
Vertex repositories_[] = {8};
Vertex clients_[] = {5,6,7,1,10};
E edges_[] = {E(1,2), E(1,11), E(2,11), E(10,11), E(2,3),
		E(3,4), E(4,5), E(5,6), E(6,7), E(4,8), E(7,8), E(3,9), 
		E(8,9), E(9,10)};

Size link_capacity = 490.000; // In Mbps
Weight utilities[] = {67, 80, 88, 95, 100};
Size sizes[] = {0.300, 0.700, 1.500, 2.500, 3.500}; // In Mbps
Size single_storage=1; //As a multiple of the highest quality size
Quality qualities;
unsigned seed;
bool improved = true;
//step parameters
double eps = 1.0/100;

unsigned multiplier = 1;


Requests load_requests(RequestSet& requests, const stringstream& filepath, 
	const unsigned seed, const double load
){
	stringstream filename; 
	filename<<filepath.str().c_str()<<"/load-"<<load<<"/seed-"<<seed<<"/req.dat";
	ifstream myf;
	myf.open(filename.str().c_str() );
	if(!myf.is_open() )
	{
		cout<<"Error reading file "<<filename.str().c_str()<<endl;
		exit(1);
	}
	string line;
	getline(myf,line) ;
	char_separator<char> sep("<>"); //Inspired by http://stackoverflow.com/a/55680/2110769
    tokenizer< char_separator<char> > tokens(line, sep);
	Requests tot_requests =0;
	unsigned count=1;
    for (const auto& t : tokens) 
	{
		if (count%2==0)
		{
			unsigned o,cli,n; o=cli=n=0;
			sscanf(t.c_str(), "%u,%u,%u", &o,&cli,&n);
			requests.emplace(pair<Vertex,Object>(cli,o) , n) ;
			tot_requests += n;
		}
		count++;
    }
	myf.close();
	return tot_requests;
}

Requests generate_requests(RequestSet& requests, const double alpha, const Object ctlg,
	const double load
){
	Requests tot_requests = 0;
	Requests avg_tot_requests = (Requests) (load*link_capacity/sizes[0] );

	ZipfGenerator zipf(alpha, ctlg, seed, avg_tot_requests);
	for (Vertex cli_id = 0; cli_id < sizeof(clients_)/sizeof(Vertex); cli_id++ )
	for(Object o=1; o<=ctlg; o++)
	{
		Requests n = zipf.generate_requests(o);
		requests.emplace(pair<Vertex,Object>(clients_[cli_id],o) , n) ;
		tot_requests += n;
	}
	cout <<"tot_requests "<< tot_requests<<endl;
	return tot_requests;
}

// Returns the total number of requests
Requests initialize_requests(RequestSet& requests)
{
	requests.emplace(pair<Vertex,Object>(1,1) , 100*multiplier) ;
	requests.emplace(pair<Vertex,Object>(1,2) , 50*multiplier) ;
	requests.emplace(pair<Vertex,Object>(1,3) , 25*multiplier) ;
	requests.emplace(pair<Vertex,Object>(1,4) , 13*multiplier) ;
	requests.emplace(pair<Vertex,Object>(1,5) , 6*multiplier) ;
	requests.emplace(pair<Vertex,Object>(1,6) , 3*multiplier) ;
	requests.emplace(pair<Vertex,Object>(1,7) , 2*multiplier) ;
	requests.emplace(pair<Vertex,Object>(1,8) , 1*multiplier) ;

	requests.emplace(pair<Vertex,Object>(2,1) , 100*multiplier) ;
	requests.emplace(pair<Vertex,Object>(2,2) , 50*multiplier) ;
	requests.emplace(pair<Vertex,Object>(2,3) , 25*multiplier) ;
	requests.emplace(pair<Vertex,Object>(2,4) , 13*multiplier) ;
	requests.emplace(pair<Vertex,Object>(2,5) , 6*multiplier) ;
	requests.emplace(pair<Vertex,Object>(2,6) , 3*multiplier) ;
	requests.emplace(pair<Vertex,Object>(2,7) , 2*multiplier) ;
	requests.emplace(pair<Vertex,Object>(2,8) , 1*multiplier) ;

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

	// Associates to each object a map associating to each client the set of its optimal values
	// to retrieve that object
	BestSrcMap best_cache_map;

	IncarnationCollection unused_incarnations;

	MyMap<Vertex,Size> cache_occupancy;

	Size max_size;
	Weight max_utility;
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

void print_distances (const vector<Vertex>& sources, const vector<Vertex>& clients, Graph G)
{
	vector<Weight> tmp_distances_from_single_source(num_vertices(G));
	vector<Vertex> tmp_predecessors(num_vertices(G));

	cout<<"distances ";
	for(vector<Vertex>::const_iterator it_src = sources.begin(); 
			it_src != sources.end(); ++it_src
	){
		Vertex src = *it_src;
		compute_paths_from_source(src, clients, G,
					tmp_distances_from_single_source, tmp_predecessors);
		MyMap<Vertex, Weight> tmp_distances_to_src_map;
		for(vector<Vertex>::const_iterator it_cli = clients.begin(); 
				it_cli != clients.end(); ++it_cli
		){
			Vertex cli = *it_cli;
			tmp_distances_to_src_map.emplace(cli, tmp_distances_from_single_source[cli] );
			cout<<"d("<<src<<","<<cli<<")="<<tmp_distances_from_single_source[cli]<<"; ";
		}
	}
	cout << endl;
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
 * out_best_repo_map will associate to each client a pair containing the best repo and the distance to reach it,
 * only in case this association is benefiting, meaning that there is a quality at which the pure  utility when 
 * downloading an object at that quality is greater than the cost
 */
void fill_best_repo_map(
		const vector<Vertex>& repositories, 
		const vector<Vertex>& clients,
		const MyMap< Vertex, MyMap<Vertex,Weight > >& distances,// The key is the 
																// source. The value is a map
																// associating to each client
																// its distance from the source
		MyMap< Vertex, OptimalClientValues >& out_best_repo_map
){
	// {FIND THE CLOSEST REPOS
	// For each client, we compute its closest repo
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
	// }FIND THE CLOSEST REPOS

	//{ FIND THE BEST QUAL
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
		if (best_utility>0)
		{
			OptimalClientValues best;
			best.src=repo; best.distance=distance; 
			best.q= best_q; best.per_req_gross_utility=best_utility;
			out_best_repo_map.emplace(client, best );
		}//else it is better not to serve this object than retrieving it from the repository.
		 // Still, we may find a placement in the cache that allows us to retrieve it
	}
	//} FIND THE BEST QUAL

	#ifdef VERBOSE
	cout<<"cli-repo association:"<<endl;
	for (MyMap< Vertex, OptimalClientValues >::iterator it=out_best_repo_map.begin();
		it != out_best_repo_map.end(); ++it
		)
	{
		Vertex client = it->first;
		OptimalClientValues best = it->second;
		cout<<client<<":"<<best.src<<":"<<best.distance<<":"<<
				unsigned(best.q)<<":"<<best.per_req_gross_utility<<endl;
	}
	#endif
}


Weight compute_benefit(Incarnation& inc, const vector<Vertex> clients, const Graph& G,
		const MyMap< Vertex, MyMap<Vertex,Weight > >& distances,
		const MyMap< Vertex, OptimalClientValues >& best_repo_map ,
		const BestSrcMap& best_cache_map, 
		const MyMap<Vertex,Size>& cache_occupancy,
		vector<Vertex>& out_potential_additional_clients,
		const bool normalized // if "normalized", the gross utility will be divided by size 
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
			RequestSet::const_iterator req_it = requests.find(pair<Vertex,Object>(cli,obj) );
			
			if(req_it != requests.end() )
			{
				Requests n = req_it->second;
				if (u_new>0 && n>0)
				{
					Weight u_cache = 0;
					BestSrcMap::const_iterator bcp_it = best_cache_map.find(obj);
					if(bcp_it != best_cache_map.end() )
					{
						MyMap<Vertex,OptimalClientValues> opt_cache_values_per_obj = bcp_it->second;
						MyMap<Vertex,OptimalClientValues>::iterator ocv_it = 
								opt_cache_values_per_obj.find(cli);
						if (ocv_it != opt_cache_values_per_obj.end() )
						{
							OptimalClientValues& opt_val_to_cache = opt_cache_values_per_obj.at(cli);
							u_cache = opt_val_to_cache.per_req_gross_utility;
						} // else there is no cache location that serves that object to
						  // that client
					}// else There is no good cache location, and thus the best utility we could 
					 // get (before considering the new incarnation) is provided by the best repo

					Weight u_best=0; 	// If the best_utility remains 0, it means that the object is 
										// currently not served to the client
					if (u_cache > 0)
					{
						// We found some cache serving that object to that client. By construction
						// it is better than any repo.
						u_best = u_cache;
					}else{
						// No cache is serving that object to that client. We verify whether there is 
						// a repository serving that
						MyMap< Vertex, OptimalClientValues >::const_iterator opt_val_to_repo_it =
							best_repo_map.find(cli);
						if (opt_val_to_repo_it != best_repo_map.end() )
						{
							// There is a repository currently serving cli
							OptimalClientValues opt_val_to_repo = opt_val_to_repo_it->second;
							u_best = opt_val_to_repo.per_req_gross_utility;
							#ifdef SEVERE_DEBUG
								if(u_best<=0) throw invalid_argument("u_repo cannot be negative");
							#endif
						}
					}

					if (u_new > u_best)
					{
						benefit += n * (u_new - u_best);
						if (normalized) benefit = benefit / sizes[q_new];
						out_potential_additional_clients.push_back(cli);
					} // else the benefit is not incremented
				}
			} // else there are no requests for that object from that client
		} //end of for
	} 	// Else benefit remains 0, in order to avoid to insert this element, since there is no room
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

template <typename T>
double compute_norm(const T& ic )
{
	double norm=0;
	for (typename T::const_iterator it=ic.begin(); 
			it!=ic.end(); ++it)
	{
		norm += (*it) * (*it);
	}
	return sqrt(norm);
}


template <typename T>
void print_collection(const T& ic )
{
	for (typename T::const_iterator it=ic.begin(); 
			it!=ic.end(); ++it)
	{
		cout<<*it<<" ";
	}
	cout<<endl;
}

void print_occupancy(const MyMap<Vertex,Size>& cache_occupancy )
{
	cout<<"Occupancy: ";
	for (MyMap<Vertex,Size>::const_iterator it=cache_occupancy.begin(); 
			it!=cache_occupancy.end(); ++it)
	{
		Vertex cache = it->first;
		Size s = it->second;
		cout<<cache<<":"<<s<<"----";
	}
	cout<<endl;
}
	// Associates to each source a map associating to each client the distance to that source
	;


Weight compute_per_req_gross_utility(const Incarnation& inc, Vertex cli,
	const MyMap< Vertex, MyMap<Vertex,Weight > >& distances
){
	Weight d = distances.at(inc.src).at(cli);
	return utilities[inc.q] - sizes[inc.q] * d;
}

void add_load(EdgeValues& loads, const E e, const Weight load)
{
	throw invalid_argument("Implement this");
}

// Add load to the links of the best path between src and cli
void update_load(EdgeValues& edge_load_map, 
	const Graph& G, const MyMap<Vertex, vector<Vertex> >& predecessors_to_source, 
	const Vertex src, const Vertex cli, const Weight load
){
	// Associates to each source a vector, having in the i-th position the predecessor of 
	// the i-th node toward that source
	const vector<Vertex> path = predecessors_to_source.at(src);
	// Iteration through the path inspired by http://stackoverflow.com/a/12676435
	graph_traits< Graph >::vertex_descriptor current;
	for (current=cli; current!= src; current =  path[current] )
	{
		EdgeDescriptor e = edge(current,path[current],G).first;
		Weight old_load = 0;
		EdgeValues::iterator it = edge_load_map.find(e) ;
		if (it != edge_load_map.end() )
			old_load = it->second;
		edge_load_map[e] = old_load + load;
	}
}

// Returns the amount of requests that can be satisfied considering the 
// bottleneck of the path
Requests compute_satisfiable(const EdgeValues& edge_load_map, 
	const Graph& G, const MyMap<Vertex, vector<Vertex> >& predecessors_to_source, 
	const Vertex src, const Vertex cli, const Quality q
){
	bool overload = false;
	// Associates to each source a vector, having in the i-th position the predecessor of 
	// the i-th node toward that source
	const vector<Vertex> path = predecessors_to_source.at(src);
	// Iteration through the path inspired by http://stackoverflow.com/a/12676435
	graph_traits< Graph >::vertex_descriptor current;
	Requests satisfiable;
	for (current=cli; current!= src && overload==false; current =  path[current] )
	{
		EdgeDescriptor e = edge(current,path[current],G).first;
		Weight old_load = 0;
		EdgeValues::const_iterator it = edge_load_map.find(e) ;
		if (it != edge_load_map.end() )
			old_load = it->second;
		if (old_load>=link_capacity) return 0;
		else if ( current==cli || (Requests) ( (link_capacity - old_load)/  sizes[q]) < satisfiable)
			satisfiable = (Requests) ( (link_capacity - old_load)/  sizes[q]);
	}
	return satisfiable;
}


void print_path(const EdgeValues& edge_load_map, const EdgeValues& edge_weight_map,
	const Graph& G, const MyMap<Vertex, vector<Vertex> >& predecessors_to_source, 
	const Vertex src, const Vertex cli
){
	// Associates to each source a vector, having in the i-th position the predecessor of 
	// the i-th node toward that source
	const vector<Vertex> path = predecessors_to_source.at(src);
	// Iteration through the path inspired by http://stackoverflow.com/a/12676435
	graph_traits< Graph >::vertex_descriptor current;
	for (current=cli; current!= src; current =  path[current] )
	{
		const EdgeDescriptor ed = edge(current,path[current],G).first;
		cout<<ed<<":l"<< edge_load_map.find(ed)->second<<":w"<< 
				edge_weight_map.find(ed)->second <<"-";
	}
}


void print_edge_load_map(const EdgeValues& edge_load_map)
{
	for (EdgeValues::const_iterator it = edge_load_map.begin(); it!=edge_load_map.end() ; ++it)
	{
		cout<< it->first << ":" << it->second << " ";
	}
	cout <<endl;
}

void print_mappings(const EdgeValues& edge_load_map, const EdgeValues& edge_weight_map, 
	const RequestSet& requests, const Graph& G,
	const MyMap< Vertex, OptimalClientValues >& best_repo_map, 
	const MyMap<Vertex, vector<Vertex> >& predecessors_to_source
){
	for (RequestSet::const_iterator r_it = requests.begin(); 
		r_it != requests.end() ; ++r_it
	){
		Vertex cli = r_it->first.first;
		Object o = r_it->first.second;
		OptimalClientValues ocv;
		BestSrcMap::const_iterator bcp_it = 
				best_cache_map.find(o);
		if ( bcp_it != best_cache_map.end() && 
			//bcp_it->second is a map of type <client, OptimalCacheValues> 
			bcp_it->second.find(cli) != bcp_it->second.end()
		){	// The object is downloaded by the cli from some cache
			ocv = bcp_it->second.find(cli)->second;
		}else{
			// the object is served by the best repository
			ocv = best_repo_map.at(cli);
		}

		Quality q = ocv.q;
		Vertex src = ocv.src;		
		cout<<o<<"->"<<cli<<":"<<ocv<<":";
		print_path(edge_load_map,edge_weight_map, G, predecessors_to_source, src, cli);
		cout<<endl;
	}
}

// Return the average pure utility
void compute_edge_load_map_and_pure_utility(EdgeValues& edge_load_map, 
	const Graph& G,
	const MyMap<Vertex, 	vector<Vertex> >& predecessors_to_source, 
	const vector<E>& edges, 
	const RequestSet& requests,
	const MyMap< Vertex, OptimalClientValues >& best_repo_map, 
	const BestSrcMap& best_cache_map,
	Weight& out_tot_pure_utility,
	Weight& out_tot_gross_utility,
	const bool overload_possible
){
	out_tot_pure_utility=0;
	out_tot_gross_utility = 0;
	edge_load_map.clear();

	multimap< Requests, pair<Vertex,Object> > requests_flipped = flip_map(requests);
	for (multimap< Requests, pair<Vertex,Object> >::reverse_iterator r_it = requests_flipped.rbegin(); 
		r_it != requests_flipped.rend() ; ++r_it
	){
		Vertex cli = r_it->second.first;
		Object o = r_it->second.second;
		Requests n = r_it->first; // How many times o is requested by cli
		bool is_served = false;
		OptimalClientValues ocv;
		BestSrcMap::const_iterator bcp_it = 
				best_cache_map.find(o);
		if ( // That object is cached somewhere
			bcp_it != best_cache_map.end() && 

			// The client is downloading that object from some cache
			// bcp_it->second is a map of type <client, OptimalCacheValues> 
			bcp_it->second.find(cli) != bcp_it->second.end()

		){
			ocv = bcp_it->second.find(cli)->second;
			is_served = true;
		}else{
			MyMap< Vertex, OptimalClientValues >::const_iterator brm_it = best_repo_map.find(cli);
			if (brm_it != best_repo_map.end() )
			{
				// the object is served by the best repository
				ocv = best_repo_map.at(cli);
				is_served = true;
			}
		}

		if (is_served)
		{
			Quality q = ocv.q;
			Vertex src = ocv.src;
			Requests satisfied;
			if (!overload_possible)
			{
				satisfied = compute_satisfiable(edge_load_map, 
					G, predecessors_to_source, src, cli, q );
				if (satisfied>n) satisfied = n;
			}else
				satisfied = n;

			Weight load = satisfied * sizes[q];
			out_tot_pure_utility += utilities[q] * satisfied;
			out_tot_gross_utility += ( utilities[q] - ocv.distance * sizes[q] ) * satisfied;
			#ifdef SEVERE_DEBUG
					if (utilities[q] - ocv.distance * sizes[q] != ocv.per_req_gross_utility )
					{
						throw invalid_argument("Invalid ocv");
					}
					if(ocv.per_req_gross_utility<0)
					{
						stringstream os; os << "This OptimalClientValues is erroneous as the gross "
							<<"utility cannot be negative: "<<ocv;
						throw invalid_argument(os.str().c_str());
					}
			#endif
			update_load(edge_load_map, G, predecessors_to_source, src, cli, load );
			
		}
	}
}

// Returns the tot_pure_utility
void greedy(EdgeValues& edge_load_map, const EdgeValues& edge_weight_map, 
	const vector<E>& edges, const Graph& G,
	Weight& tot_pure_utility_cleaned, Weight& tot_gross_utility, 
	const bool normalized // Paramater of compute_benefit
){

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
	max_utility=0; for (const Weight& u: utilities) if (u>max_utility) max_utility=u;
	//} INITIALIZE INPUT DATA STRUCTURE
	
	// Associates to each source a map associating to each client the distance to that source
	MyMap< Vertex, MyMap<Vertex,Weight > > distances;
	fill_distances(sources, clients, G, predecessors_to_source, distances);
	#ifdef SEVERE_DEBUG
		print_distances(sources, clients, G);
	#endif

	// Associates to each client, the best repository and the corresponding optimal information
	MyMap< Vertex, OptimalClientValues > best_repo_map;
	fill_best_repo_map(repositories, clients, distances, best_repo_map);

	for (vector<Vertex>::iterator it=caches.begin(); it!= caches.end(); ++it)
	{
		Vertex cache = *it; cache_occupancy.emplace(cache,0);
	}

	//{ INITIALIZE INCARNATIONS
	#ifdef VERBOSE	
	cout << "Initializing incarnations"<<endl;
	#endif
	for(vector<Object>::iterator obj_it = objects.begin(); obj_it != objects.end(); ++obj_it)
	for(vector<Vertex>::iterator cache_it = caches.begin(); cache_it != caches.end(); ++cache_it)
	for(Quality q=0; q<qualities; q++)
	{
		Incarnation inc; inc.o = *obj_it; inc.q = q; inc.src=*cache_it;
		vector<Vertex> potential_additional_clients; // I am not interested in this for the
															// time being
		Weight b= compute_benefit(inc, clients, G, distances, best_repo_map, 
			best_cache_map, cache_occupancy, potential_additional_clients, normalized);
		inc.benefit=b;
		if (inc.benefit > 0)
			unused_incarnations.push_back(inc);
		// else it is not worth considering it
	}
	unused_incarnations.sort(compare_incarnations);
	#ifdef VERBOSE
	cout<<"unused incarnations: "; print_collection(unused_incarnations);
	print_occupancy(cache_occupancy);
	unsigned greedy_iteration = 0;
	#endif
	//} INITIALIZE INCARNATIONS



	while (unused_incarnations.size()>0)
	{
		#ifdef VERBOSE
		cout<<"######## greedy_iteration "<< ++greedy_iteration<<endl;
		#endif
		Incarnation best_inc = unused_incarnations.front();
		unused_incarnations.pop_front();
//		selected_incarnations.push_back();

		#ifdef SEVERE_DEBUG
		cout<< "Selected incarnation "<<best_inc<<endl;
		if (best_inc.benefit <= 0)
		{
			stringstream os; os << "The selected incarnation is "<<best_inc<<
				" and its benefit is "<<best_inc.benefit<<". However, an \
				incarnation with non-positive benefits should be not considered";
			throw std::invalid_argument(os.str().c_str() );
		}

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
				best_cache_map, cache_occupancy, changing_clients, normalized);

			#ifdef SEVERE_DEBUG
			if (changing_clients.size()==0)
			{
				char msg[200];
				stringstream os; os << "Storing last incarnation "<<best_inc<<" seems not to influence any\
					client, and thus is useless. Anyway, its benefit is supposed to be "<<b;
				throw std::invalid_argument(os.str().c_str() );
			}
			#endif

			#ifdef VERBOSE
			cout<<"changing clients:";
			#endif
			// Update best_cache_map
			for(vector<Vertex>::iterator cli_it = changing_clients.begin(); 
				cli_it != changing_clients.end(); ++cli_it
			){
				Vertex cli = *cli_it;
				OptimalClientValues new_opt_val_to_cache;
				new_opt_val_to_cache.src = best_inc.src;
				new_opt_val_to_cache.distance = distances.at(best_inc.src).at(cli);
				new_opt_val_to_cache.q = best_inc.q;
				new_opt_val_to_cache.per_req_gross_utility = 
					compute_per_req_gross_utility(best_inc, cli, distances);
				best_cache_map[best_inc.o][cli] = new_opt_val_to_cache;
				#ifdef VERBOSE
				cout<<cli<<":";
				#endif
			}
			#ifdef VERBOSE
			cout<<endl;
			#endif

			//{ RECOMPUTE THE BENEFITS
			cache_occupancy[best_inc.src] = cache_occupancy[best_inc.src] + sizes[best_inc.q];

			for (IncarnationCollection::iterator inc_c_it = unused_incarnations.begin();
				inc_c_it != unused_incarnations.end(); ++inc_c_it
			)
			{
				Incarnation& inc = *inc_c_it;
				inc.benefit = compute_benefit(inc, clients, G, distances, best_repo_map, 
					best_cache_map, cache_occupancy, changing_clients, normalized);
			}
			//} RECOMPUTE THE BENEFITS
			
			unused_incarnations.sort(compare_incarnations);
			//std::sort(unused_incarnations.rbegin(), unused_incarnations.rend() );

			#ifdef VERBOSE
			print_occupancy(cache_occupancy);
			cout<<"unused incarnation: "; print_collection(unused_incarnations); cout<<endl;
			#endif

			//{ PURGE USELESS INCARNATIONS
			// At the end we find all the zero-benefit incarnations
			IncarnationCollection::iterator ui_it = unused_incarnations.end(); ui_it--;
			#ifdef VERBOSE
			unsigned to_erase = 0;
			cout<<"I am considering "<<*ui_it<<endl;
			#endif
			while (ui_it->benefit <= 0 && ui_it != unused_incarnations.begin() )
			{
				--ui_it;
				#ifdef VERBOSE
				to_erase++;
				#endif
			}
			#ifdef VERBOSE
			cout<<"I am going to remove "<<to_erase<<" elements over "<<
				unused_incarnations.size()<<endl;
			#endif
			unused_incarnations.erase(ui_it, unused_incarnations.end() );
			//} PURGE USELESS INCARNATIONS
		//{ UPDATE DATA AFTER SELECTION

	}

	bool overload_possible = true;
	Weight tot_pure_utility_tmp;
	compute_edge_load_map_and_pure_utility(
			edge_load_map, G,
			predecessors_to_source, edges, 
			requests, best_repo_map, best_cache_map,
			tot_pure_utility_tmp, tot_gross_utility, 
			overload_possible);
	#ifdef VERBOSE
	print_mappings(edge_load_map, edge_weight_map, requests, G, best_repo_map,
		predecessors_to_source);
	#endif

	overload_possible = false;
	EdgeValues edge_load_map_cleaned;
	Weight tot_gross_utility_tmp;
	compute_edge_load_map_and_pure_utility(
			edge_load_map_cleaned, G,
			predecessors_to_source, edges, 
			requests, best_repo_map, best_cache_map,
			tot_pure_utility_cleaned, tot_gross_utility_tmp, 
			overload_possible);
}

void fill_weight_map(EdgeValues& edge_weight_map, 
	const vector<E>& edges, const vector<Weight>& weights, const Graph& G)
{
	for (unsigned e_id=0; e_id<weights.size(); e_id++)
	{
		EdgeDescriptor ed = edge(edges.at(e_id).first, edges.at(e_id).second ,G).first;
		edge_weight_map[ed] = weights[e_id];
	}
}

void update_weights(vector<Weight>& weights, double step, const vector<Weight>& violations)
{
	for (unsigned eid=0; eid<weights.size(); eid++)
			weights[eid] =	weights[eid] + step * violations[eid] > 0 ? 
							weights[eid] + step * violations[eid] :0;
}

int main(int argc,char* argv[])
{
	if (argc != 6)
	{
		cout<<"usage: "<<argv[0]<<" <alpha> <ctlg> <load> <iterations> <seed>"<<endl;
		exit(1);
	}
	Weight min_gross_utility = DBL_MAX;
	double alpha = atof(argv[1]);
	Object ctlg = strtoul(argv[2], NULL, 0);
	double load = atof(argv[3]);
	unsigned num_iterations = strtoul(argv[4], NULL, 0);
	seed = strtoul(argv[5], NULL, 0);
	
	// Parameter for the step update
	unsigned M = num_iterations/10;

	//{ CREATE REQUESTS
	// Requests tot_requests = initialize_requests(requests);
	// Requests tot_requests = generate_requests(requests, alpha, ctlg, load);
	stringstream filepath; filepath<<"/home/araldo_local/software/araldo-phd-code/utility_based_caching/examples/multi_as/request_files/abilene/ctlg-100/alpha-1";
	Requests tot_requests = load_requests(requests, filepath, seed, load);

	//} CREATE REQUESTS

	//{ INITIALIZE INPUT DATA STRUCTURE
	vector<E> edges(edges_, edges_+sizeof(edges_)/sizeof(E) );
	vector<Size> tmp_sizevec(sizes, sizes+sizeof(sizes)/sizeof(Size)  );
	double avg_size = compute_norm(tmp_sizevec );
	Weight init_w=0/(tot_requests*avg_size); // Initialization weight
	vector<Weight>weights(sizeof(edges_)/sizeof(E), init_w);
	//} INITIALIZE INPUT DATA STRUCTURE

	Weight first_violation_norm=0;
	double first_step, old_step;
	for (unsigned k=1; k<=num_iterations; k++)
	{
		cout<<"\n\n################# ITER "<<k<<endl;
		unsigned num_nodes = count_nodes(edges);
		Graph G(edges_, edges_ + sizeof(edges_)/sizeof(E), weights.data(), num_nodes);
		EdgeValues edge_weight_map;
		fill_weight_map(edge_weight_map, edges, weights, G);

		//{ COMPUTE THE UTILITY
		Weight tot_pure_utility_cleaned, tot_gross_utility,
			tot_pure_utility_cleaned_with_normalization, tot_gross_utility_with_normalization,
			tot_pure_utility_cleaned_without_normalization, tot_gross_utility_without_normalization;
		bool normalized=true;
		EdgeValues edge_load_map, edge_load_map_with_normalization, 
				edge_load_map_without_normalization;

		greedy(edge_load_map_with_normalization, edge_weight_map, edges, G, 
			tot_pure_utility_cleaned_with_normalization, tot_gross_utility_with_normalization,
			normalized
		);
		if (improved)
		{
			normalized=false;
			greedy(edge_load_map_without_normalization, edge_weight_map, edges, G, 
				tot_pure_utility_cleaned_without_normalization, tot_gross_utility_without_normalization,
				normalized
			);
		}

		if (tot_gross_utility_with_normalization >= tot_gross_utility_without_normalization ||
			!improved
		){
			normalized=true;
			tot_gross_utility = tot_gross_utility_with_normalization;
			tot_pure_utility_cleaned = tot_pure_utility_cleaned_with_normalization;
			edge_load_map = edge_load_map_with_normalization;
		}
		else{
			normalized=false;
			tot_gross_utility = tot_gross_utility_without_normalization;
			tot_pure_utility_cleaned = tot_pure_utility_cleaned_without_normalization;
			edge_load_map = edge_load_map_without_normalization;
		}
		//} COMPUTE THE UTILITY
		
	
		#ifdef SEVERE_DEBUG
			Weight tot_gross_utility_2 = tot_pure_utility;
		#endif
		#ifdef VERBOSE
			cout<<"edge_load_map: "; 	print_edge_load_map(edge_load_map);
		#endif
		// Compute the violations
		vector<Weight> violations; violations.reserve(edges.size());
		for (unsigned eid=0; eid<edges.size(); eid++)
		{
			EdgeDescriptor e = edge(edges[eid].first, edges[eid].second ,G).first;
			violations[eid] = edge_load_map[e] - link_capacity;
			if (k==1) first_violation_norm += violations[eid]*violations[eid] ;
			#ifdef SEVERE_DEBUG
				tot_gross_utility_2 -=  weights[eid] * edge_load_map[e];
			#endif
		}
		#ifdef SEVERE_DEBUG
			if ( abs(tot_gross_utility - tot_gross_utility_2 ) / tot_requests > max_utility )
			{
				stringstream os; os<<"Error in utility computation at iteration "<<
					k<<": gross_utility="<<
					tot_gross_utility/tot_requests<<"; gross_utility_2="<<
					tot_gross_utility_2/tot_requests;
				throw invalid_argument(os.str().c_str());
			}
			if (tot_gross_utility<0)
			{
				stringstream os; os<<"tot_gross_utility is "<<tot_gross_utility<<
					" while it can't be negative";
				throw std::invalid_argument(os.str().c_str());
			}
		#endif

		//{ STEP SIZE
		double step;
		if (k==1)
		{
			first_violation_norm = sqrt(first_violation_norm);
			first_step = link_capacity / first_violation_norm;
			step = first_step;
		}else
		{
			step = old_step * pow( 1- 1/ (1+M+k), 0.5+eps );
		}
		old_step = step;
		cout <<"step "<<step<<endl;
		//} STEP SIZE

		cout<<"violations ";
		for (unsigned eid=0; eid<edges.size(); eid++) cout<<violations[eid]<<" ";
		cout<<endl;

		update_weights(weights, step, violations);
		if (tot_gross_utility < min_gross_utility)
			min_gross_utility = tot_gross_utility;

		cout<<"new_weights: "; print_collection(weights);
		cout<<"tot_requests "<<tot_requests<<endl;
		cout<<"avg_gross_utility "<<tot_gross_utility/tot_requests<<endl;
		cout<<"min_gross_utility "<<min_gross_utility/tot_requests<<endl;
		cout<<"avg_pure_utility_cleaned "<<tot_pure_utility_cleaned/tot_requests<<endl;

		//Implement the tilde{psi} di math_paper
	}
	return 0;
}
