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

// Change here to change the network
#include "networks/abilene.hpp"

#define SEVERE_DEBUG
//#define VERBOSE


using namespace boost;
using namespace std;





Quality qualities;
unsigned seed;
bool improved = true; // Implements Algorithm 3 of Horel, T. (2015). Notes on Greedy Algorithms for Submodular Maximization.
//step parameters
double eps = 1.0/100;

unsigned multiplier = 1;


Requests load_requests(RequestSet& requests, const char* reqfilename)
{
	ifstream myf;
	myf.open(reqfilename );
	if(!myf.is_open() )
	{
		cout<<"Error reading file "<<reqfilename<<endl;
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
	for (Vertex cli_id = 0; cli_id < sizeof(clients_in_case_of_generation)/sizeof(Vertex); cli_id++ )
	for(Object o=1; o<=ctlg; o++)
	{
		Requests n = zipf.generate_requests(o);
		requests.emplace(pair<Vertex,Object>(clients_in_case_of_generation[cli_id],o) , n) ;
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

	Size max_size;
	Weight max_utility;
//} DATA STRUCTURES



Size compute_tot_cache_occupancy(const MyMap<Vertex,Size>& cache_occupancy)
{
	Size tot_cache_occupancy =0;
	for (MyMap<Vertex,Size>::const_iterator it=cache_occupancy.begin(); 
			it!=cache_occupancy.end(); ++it)
	{
		Vertex cache = it->first;
		Size s = it->second;
		tot_cache_occupancy += s;
	}
	return tot_cache_occupancy;
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
 * only in case this association is benefiting, meaning that there is a quality at which the feasible  utility when 
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
	#ifdef SEVERE_DEBUG
	if (closest_repo.size()==0)
		throw runtime_error("closest_repo has 0 elements");
	#endif
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
	cout<<"cli-repo association (cli:src:dist:q:gross_u)";
	unsigned count=0;
	for (MyMap< Vertex, OptimalClientValues >::iterator it=out_best_repo_map.begin();
		it != out_best_repo_map.end(); ++it
		)
	{	count++;
		Vertex client = it->first;
		OptimalClientValues best = it->second;
		cout<<endl<<client<<":"<<best.src<<":"<<best.distance<<":"<<
				unsigned(best.q)<<":"<<best.per_req_gross_utility;
	}
	if (count==0)
		cout<<" it is better not to serve any object from the repository";

	cout<<endl;
	#endif
}


Weight compute_benefit(Incarnation& inc, const vector<Vertex> clients, const Graph& G,
		const MyMap< Vertex, MyMap<Vertex,Weight > >& distances,
		const MyMap< Vertex, OptimalClientValues >& best_repo_map ,
		const BestSrcMap& best_cache_map, 
		const MyMap<Vertex,Size>& cache_occupancy,
		vector<Vertex>& out_potential_additional_clients,
		const bool normalized, // if "normalized", the gross utility will be divided by size 
		const Size single_storage
){
	Weight benefit=0;

	Object obj = inc.o;
	Vertex src_new = inc.src;
	Quality q_new = inc.q;
	Size size_new = sizes[q_new];
	
	if ( cache_occupancy.at(src_new) + size_new <= single_storage * max_size + 1e-5)
	{	// We have space to place this incarnation and the benefit may be > 0

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
				// cli is requesting this object
				Requests n = req_it->second;
				if (u_new>0 && n>0)
				{
					Weight u_cache = 0;
					BestSrcMap::const_iterator bcp_it = best_cache_map.find(obj);
					if(bcp_it != best_cache_map.end() )
					{
						// This object is already in some cache
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

	inc.benefit = benefit; inc.valid=true;
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

#ifdef SEVERE_DEBUG
void verify_cache(const MyMap<Vertex,Size>& cache_occupancy, const Size single_storage )
{
	for (MyMap<Vertex,Size>::const_iterator it=cache_occupancy.begin(); 
			it!=cache_occupancy.end(); ++it)
	{
		Vertex cache = it->first;
		Size s = it->second;
			if (s>single_storage*max_size + 1e5)
			{
				char msg[200];
				sprintf(msg,"Storage constraints not verified:single_storage=%g HQ objects, which means space %g of storage. Despite this, cache %lu has %g of space occupied",
					single_storage, single_storage*max_size, cache, s);
				throw std::invalid_argument(msg);
			}
	}
}
#endif


void print_occupancy(const MyMap<Vertex,Size>& cache_occupancy, const Size single_storage )
{
	cout<<"Occupancy(cache:occupation): ";
	for (MyMap<Vertex,Size>::const_iterator it=cache_occupancy.begin(); 
			it!=cache_occupancy.end(); ++it)
	{
		Vertex cache = it->first;
		Size s = it->second;
		cout<<cache<<":"<<s<<"----";
			if (s>single_storage*max_size + 1e5)
			{
				char msg[200];
				sprintf(msg,"Storage constraints not verified:single_storage=%g HQ objects, which means space %g of storage. Despite this, cache %lu has %g of space occupied",
					single_storage, single_storage*max_size, cache, s);
				throw std::invalid_argument(msg);
			}
	}
	cout<<endl;

	#ifdef SEVERE_DEBUG
	verify_cache(cache_occupancy, single_storage);
	#endif
}

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
	const MyMap<Vertex, vector<Vertex> >& predecessors_to_source,
	const BestSrcMap& best_cache_map
){
	std::cout<<__FUNCTION__ <<":"<<std::endl;
	for (RequestSet::const_iterator r_it = requests.begin(); 
		r_it != requests.end() ; ++r_it
	){
		serving_type served=no;

		Vertex cli = r_it->first.first;
		Object o = r_it->first.second;
		OptimalClientValues ocv;
		BestSrcMap::const_iterator bcp_it = 
				best_cache_map.find(o);
		if ( bcp_it != best_cache_map.end() && 
			//bcp_it->second is a map of type <client, OptimalCacheValues> 
			bcp_it->second.find(cli) != bcp_it->second.end()
		){	// The object is downloaded by the cli from some cache
			served=cache;
			ocv = bcp_it->second.find(cli)->second;
		}else
		{
			// the object may be served by the best repository
			MyMap< Vertex, OptimalClientValues >::const_iterator best_repo_it = best_repo_map.find(cli);
			if ( best_repo_it != best_repo_map.end() )
			{
				ocv = best_repo_map.at(cli);	
				served=repo;
			}else // the object is not served at all
				served=no;
		}

		if(served != no)
		{
			Quality q = ocv.q;
			Vertex src = ocv.src;		
			cout<<o<<"->"<<cli<<":"<<ocv<<":";
			print_path(edge_load_map,edge_weight_map, G, predecessors_to_source, src, cli);
			cout<<endl;
		}else
		{
			cout<< o << "->" << cli << ": not served"<<endl;
		}
	}
}

// Return the average feasible utility
void compute_edge_load_map_and_feasible_utility(EdgeValues& edge_load_map, 
	const Graph& G,
	const MyMap<Vertex, 	
	vector<Vertex> >& predecessors_to_source, 
	const vector<E>& edges, 
	const RequestSet& requests,
	const MyMap< Vertex, OptimalClientValues >& best_repo_map, 
	const BestSrcMap& best_cache_map,
	Weight& out_tot_feasible_utility,	// It is the utility of the feasible solution
	Weight& out_lagrangian_value,	// It is the value of the lagrangian
	const bool overload_possible,
	const EdgeValues& edge_weight_map,
	const MyMap<Vertex,Size>& cache_occupancy
){
	out_tot_feasible_utility=0;
	out_lagrangian_value = 0;
	edge_load_map.clear();

	multimap< Requests, pair<Vertex,Object> > requests_flipped = flip_map(requests);
	// For each request
	for (multimap< Requests, pair<Vertex,Object> >::reverse_iterator r_it = requests_flipped.rbegin(); 
		r_it != requests_flipped.rend() ; ++r_it
	){
		Vertex cli = r_it->second.first;
		Object o = r_it->second.second;
		Requests n = r_it->first; // How many times o is requested by cli
		serving_type served = no;
		OptimalClientValues ocv;
		BestSrcMap::const_iterator bcp_it = best_cache_map.find(o);
		if ( // That object is cached somewhere
			bcp_it != best_cache_map.end() && 

			// The client is downloading that object from some cache
			// ( bcp_it->second is a map of type <client, OptimalClientValues> )
			bcp_it->second.find(cli) != bcp_it->second.end()

		){
			#ifdef SEVERE_DEBUG
			if(compute_tot_cache_occupancy(cache_occupancy) == 0)
			{
				throw runtime_error("Found an object in an empty cache");
			}
			#endif

			ocv = bcp_it->second.find(cli)->second;
			served = cache;
		}else{
			MyMap< Vertex, OptimalClientValues >::const_iterator brm_it = best_repo_map.find(cli);
			if (brm_it != best_repo_map.end() )
			{
				// the object is served by the best repository
				ocv = best_repo_map.at(cli);
				served = repo;
			}
			// Else, the object is not served
		}

		if (served!=no)
		{
			Quality q = ocv.q;
			Vertex src = ocv.src;
			Requests satisfied;
			if (!overload_possible)
			{
				// We can satisfy a request as long as we do not exceed the capacity of
				// the links across the path. 
				// Imposing this is useful to compute a feasible solution, but can be
				// ignored when dealing with the relaxed solution
				satisfied = compute_satisfiable(edge_load_map, 
					G, predecessors_to_source, src, cli, q );
				if (satisfied>n) satisfied = n;
			}else
				satisfied = n;

			Weight load = satisfied * sizes[q];	// The load imposed by the satisfaction of 
												// this request across all the links of the 
												// path
			out_tot_feasible_utility += utilities[q] * satisfied;
			out_lagrangian_value += ( utilities[q] - ocv.distance * sizes[q] ) * satisfied;

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
			//cout <<"updating load for o "<<o<<", src "<<src <<", cli "<<cli<<", q "<<unsigned(q)<<endl;
			update_load(edge_load_map, G, predecessors_to_source, src, cli, load );
		}
	}

	
	for (const std::pair<EdgeDescriptor,Weight>& p: edge_weight_map)
	{
		out_lagrangian_value += p.second * link_capacity;
	}
}

// Returns the tot_feasible_utility
void greedy(EdgeValues& edge_load_map, const EdgeValues& edge_weight_map, 
	const vector<E>& edges, const Graph& G,
	Weight& tot_feasible_utility_cleaned, Weight& lagrangian_value, 
	const bool normalized, // Paramater of compute_benefit
	Size single_storage
){

	qualities = sizeof(utilities)/sizeof(Weight);
	#ifdef SEVERE_DEBUG
		if (qualities != sizeof(sizes)/sizeof(Size) )
			throw std::invalid_argument("Sizes are badly specified");
	#endif

	//{ INITIALIZE DATA STRUCTURES
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
	max_utility=0; for (const Weight& u: utilities)
	{
		 if (u>max_utility) max_utility=u;
	}

	IncarnationCollection available_incarnations, useless_incarnations;
	MyMap<Vertex,Size> cache_occupancy;
	for (vector<Vertex>::iterator it=caches.begin(); it!= caches.end(); ++it)
	{
		Vertex cache = *it; cache_occupancy.emplace(cache,0);
	}

	// Associates to each object a map associating to each client the set of its optimal values
	// to retrieve that object
	BestSrcMap best_cache_map;

	#ifdef SEVERE_DEBUG
	if (edge_weight_map.size()==0)
		throw std::runtime_error("edge_weight_map is empty");
	Weight tot_gross_utility_computed_cumulatively = 0;
	for (const std::pair<EdgeDescriptor,Weight> edgeValue : edge_weight_map)	
	{
		tot_gross_utility_computed_cumulatively += edgeValue.second * link_capacity;
	}

	std::multimap<Vertex,Incarnation > cache_content;
	#endif


	//} INITIALIZE DATA STRUCTURES
	
	// Associates to each source a map associating to each client the distance to that source
	MyMap< Vertex, MyMap<Vertex,Weight > > distances;
	fill_distances(sources, clients, G, predecessors_to_source, distances);
	#ifdef VERBOSE
	print_distances(sources, clients, G);
	#endif

	// Associates to each client, the best repository and the corresponding optimal information
	MyMap< Vertex, OptimalClientValues > best_repo_map;
	fill_best_repo_map(repositories, clients, distances, best_repo_map);


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
			best_cache_map, cache_occupancy, potential_additional_clients, normalized, single_storage);
		if (inc.benefit > 0)
			available_incarnations.push_back(inc);
		else 
			// it is not worth considering it
			useless_incarnations.push_back(inc);
	}

	available_incarnations.sort(compare_incarnations);
	#ifdef SEVERE_DEBUG
	for (const Incarnation& inc : available_incarnations)
		if (!inc.valid) throw runtime_error("One available incarnation is not valid");
	for (const Incarnation& inc : useless_incarnations)
		if (!inc.valid) throw runtime_error("One available incarnation is not valid");
	if (objects.size()==0 || caches.size()==0 || qualities==0)
		throw ("objects.size()==0 || caches.size()==0 || qualities==0");
	#endif

	#ifdef VERBOSE
	cout<<"available incarnations (o:q:src:benefit): "; print_collection(available_incarnations);
	cout<<"useless incarnations (o:q:src:benefit): "; print_collection(useless_incarnations);
	print_occupancy(cache_occupancy, single_storage);
	unsigned greedy_iteration = 0;
	#endif

	#ifdef SEVERE_DEBUG
	for (const Incarnation& inc : available_incarnations)
		if (!inc.valid) throw runtime_error("One available incarnation is not valid");
	for (const Incarnation& inc : useless_incarnations)
		if (!inc.valid) throw runtime_error("One available incarnation is not valid");
	#endif

	#ifdef SEVERE_DEBUG
	for (MyMap<Vertex,Size>::const_iterator it=cache_occupancy.begin(); 
			it!=cache_occupancy.end(); ++it)
	{
		Vertex cache = it->first;
		Size s = it->second;
		if (s>0)
			throw runtime_error("I have just started. The cache cannot be occupied");
	}

	#endif
	//} INITIALIZE INCARNATIONS


	while (available_incarnations.size()>0)
	{
		#ifdef SEVERE_DEBUG
		for (const Incarnation& inc : available_incarnations)
			if (!inc.valid) throw runtime_error("One available incarnation is not valid");
		for (const Incarnation& inc : useless_incarnations)
			if (!inc.valid) throw runtime_error("One available incarnation is not valid");
		#endif


		#ifdef VERBOSE
		cout<<"######## greedy_iteration "<< ++greedy_iteration<<endl;
		#endif

		#ifdef SEVERE_DEBUG
		for (const Incarnation& inc : available_incarnations)
			if (!inc.valid) throw runtime_error("One available incarnation is not valid");
		for (const Incarnation& inc : useless_incarnations)
			if (!inc.valid) throw runtime_error("One available incarnation is not valid");
		#endif

		Incarnation best_inc = available_incarnations.front();
		available_incarnations.pop_front();
//		selected_incarnations.push_back();

		#ifdef SEVERE_DEBUG
		if (!best_inc.valid)
		{
			stringstream os; os << "The selected incarnation is "<<best_inc<<
				" but it is not valid";
			throw std::invalid_argument(os.str().c_str() );
		}

		if (best_inc.benefit <= 0)
		{
			stringstream os; os << "The selected incarnation is "<<best_inc<<
				" and its benefit is "<<best_inc.benefit<<". However, an \
				incarnation with non-positive benefits should be not considered";
			throw std::invalid_argument(os.str().c_str() );
		}

		if (sizes[best_inc.q] <= 0)
		{
			stringstream os; os << "sizes[best_inc.q] = "<< sizes[best_inc.q] <<
				" and best_inc.q = "<< best_inc.q;
			throw std::invalid_argument(os.str().c_str() );
		}

		verify_cache(cache_occupancy, single_storage);
		if (!normalized) 
			tot_gross_utility_computed_cumulatively += best_inc.benefit;
		else
			tot_gross_utility_computed_cumulatively += best_inc.benefit * sizes[best_inc.q];


		//Add the selected incarnation to the cache
		cache_content.insert( std::pair<Vertex,Incarnation> (best_inc.src,best_inc)   );
		#endif
		#ifdef VERBOSE
		cout<< "Selected incarnation "<<best_inc<<endl;
		#endif

		//{ UPDATE DATA AFTER SELECTION
			// I retrieve the clients that experience an improvement from the addition of best_inc
			// since only them change the associated source
			vector<Vertex> changing_clients;
			Weight b= compute_benefit(best_inc, clients, G, distances, best_repo_map, 
				best_cache_map, cache_occupancy, changing_clients, normalized, single_storage);
			cache_occupancy[best_inc.src] = cache_occupancy[best_inc.src] + sizes[best_inc.q];

			#ifdef VERBOSE
			print_occupancy(cache_occupancy, single_storage);
			#endif

			#ifdef SEVERE_DEBUG
			if (changing_clients.size()==0)
			{
				char msg[200];
				stringstream os; os << "Storing last incarnation "<<best_inc<<" seems not to influence any\
					client, and thus is useless. Anyway, its benefit is supposed to be "<<b;
				throw std::invalid_argument(os.str().c_str() );
			}

			// Invalidate the benefits
			for (Incarnation& inc : available_incarnations)
				inc.valid=false;
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

			#ifdef SEVERE_DEBUG
			//We verify now whether best_cache_map relies on incarnations that are really 
			//cached
			for (const std::pair<Object, MyMap<Vertex,OptimalClientValues> >& p : best_cache_map)
			{
				Object o = p.first;

				for (const pair<Vertex,OptimalClientValues>& pp : p.second)
				{
					Vertex src = pp.second.src;
					Quality q = pp.second.q;

					//{ VERIFY IF THE OBJECT IS REALLY CACHED AT THE INTENDED QUALITY
					bool found = false;
					std::pair <std::multimap<Vertex,Incarnation>::iterator, std::multimap<Vertex,Incarnation>::iterator> ret;
					ret = cache_content.equal_range(src);
					for (std::multimap<Vertex,Incarnation>::iterator it=ret.first; it!=ret.second; ++it)
					{
						Object cached_o = (it->second).o;
						Quality cached_q = (it->second).q;
						if (cached_o == o && cached_q == q)
						{
							if (found == true)
							{
								std::stringstream msg; msg<<"You found object "<<o<<" at quality "<<q<<
									", which was already found in the same cache";
								throw std::runtime_error(msg.str() );
							}
							found = true;
						}
					}
					if (!found)
					{
						std::stringstream msg; msg<<"I thought object "<<o<<" was served by cache "<<src<<
							" at quality "<<q<<", but it is not the case";
						throw std::runtime_error(msg.str() );
					}
					//} VERIFY IF THE OBJECT IS REALLY CACHED AT THE INTENDED QUALITY
				}
			}
			#endif

			//{ RECOMPUTE THE BENEFITS
			for (Incarnation& inc : available_incarnations)
			{
				inc.benefit = compute_benefit(inc, clients, G, distances, best_repo_map, 
					best_cache_map, cache_occupancy, changing_clients, normalized, single_storage);
			}
			//} RECOMPUTE THE BENEFITS
			
			available_incarnations.sort(compare_incarnations);
			//std::sort(available_incarnations.rbegin(), available_incarnations.rend() );

			#ifdef VERBOSE
			cout<<"available incarnation: "; print_collection(available_incarnations); cout<<endl;
			#endif

			//{ PURGE USELESS INCARNATIONS
			// At the end we find all the zero-benefit incarnations
			IncarnationCollection::iterator ui_it = available_incarnations.end();
			ui_it--;
			#ifdef VERBOSE
			unsigned to_erase = 1;
			#endif
			while (ui_it->benefit <= 0 && ui_it != available_incarnations.begin() )
			{
				--ui_it;
				#ifdef VERBOSE
				to_erase++;
				#endif
			}
			// I check the first incarnation separately
			if (ui_it == available_incarnations.begin() && ui_it->benefit > 0)
			{	// Mi rimangio la parola
				++ui_it;
				#ifdef VERBOSE
				to_erase--;
				#endif
			}


			#ifdef VERBOSE
			cout<<to_erase<<" out of "<<available_incarnations.size() <<" available_incarnations are "
				"being removed since they provide no benefit" <<endl;
			#endif
			available_incarnations.erase(ui_it, available_incarnations.end() );
			#ifdef VERBOSE
			cout<<"now available incarnations are: "; print_collection(available_incarnations); cout<<endl;
			#endif
			//} PURGE USELESS INCARNATIONS
		//{ UPDATE DATA AFTER SELECTION

	}

	//{ COMPUTE THE LAGRANGIAN
	bool overload_possible = true;
	Weight tot_feasible_utility_tmp; // We will ignore it
	compute_edge_load_map_and_feasible_utility(
			edge_load_map, G,
			predecessors_to_source, edges, 
			requests, best_repo_map, best_cache_map,
			tot_feasible_utility_tmp, lagrangian_value, 
			overload_possible,
			edge_weight_map,
			cache_occupancy);
	//} COMPUTE THE LAGRANGIAN
	#ifdef VERBOSE
	print_mappings(edge_load_map, edge_weight_map, requests, G, best_repo_map,
		predecessors_to_source, best_cache_map);
	#endif

	//{ COMPUTE THE FEASIBLE UTILITY
	overload_possible = false;
	EdgeValues edge_load_map_cleaned;
	Weight lagrangian_value_tmp; // We will ignore it
	compute_edge_load_map_and_feasible_utility(
			edge_load_map_cleaned, G,
			predecessors_to_source, edges, 
			requests, best_repo_map, best_cache_map,
			tot_feasible_utility_cleaned, lagrangian_value_tmp, 
			overload_possible,
			edge_weight_map,
			cache_occupancy);

	#ifdef SEVERE_DEBUG
	for (std::pair<EdgeDescriptor,Weight> p : edge_load_map_cleaned)
	{
		EdgeDescriptor e = p.first;
		Weight load = p.second;
		if (p.second > link_capacity)
		{
			std::stringstream msg; msg << "Load on link "<<e<<" is "<<load<<" while link capacity is "<<link_capacity;
			throw std::runtime_error(msg.str());
		}
	}
	verify_cache(cache_occupancy, single_storage);
	#endif
	//} COMPUTE THE FEASIBLE UTILITY
	Requests tot_requests = 0;
	for (RequestSet::iterator it = requests.begin(); it!=requests.end(); ++it)
	{
		tot_requests += it->second;
	}

	if (tot_feasible_utility_cleaned/ tot_requests > 48)
	{
		print_mappings(edge_load_map, edge_weight_map, requests, G, best_repo_map,
			predecessors_to_source, best_cache_map);

		//{ PRINT CACHE CONTENT
		for (multimap<Vertex, Incarnation>::iterator it = cache_content.begin(); it != cache_content.end(); ++it)
		{
			cout<<"cache "<<it->first <<" contains "<<it->second << std::endl; 
		}
		//} PRINT CACHE CONTENT


		stringstream msg; msg<< "tot_feasible_utility_cleaned="<< 
			tot_feasible_utility_cleaned/ tot_requests 
			<<std::endl;
		throw runtime_error(msg.str() );
	}
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

step_type parse_steps (string s)
{
	step_type value;
	if (s=="triangle")
		value = triangle;
	else if (s=="moderate")
		value = moderate;
	else{
		stringstream msg; msg<< s << " is not a valid step";
		throw invalid_argument(msg.str() );
	}
	return value;
}

int main(int argc,char* argv[])
{

	//{ INPUT
	input_type input;

	double alpha;
	Object ctlg;
	double load;
	unsigned num_iterations;
	int slowdown;
	const char* reqfilename;
	Size single_storage; //As a multiple of the highest quality size
	step_type steps;
	

	if (argc==9)
	{
		// The demand is taken from the corresponding CPLEX run
		input = automatic;
		alpha = atof(argv[1]);
		ctlg = strtoul(argv[2], NULL, 0);
		load = atof(argv[3]);
		num_iterations = strtoul(argv[4], NULL, 0);
		seed = strtoul(argv[5], NULL, 0);
		slowdown = atoi(argv[6]);
		single_storage = atof(argv[7]);
		steps = parse_steps (argv[8]);

		float c2ctlg = single_storage * ( float(sizeof(caches_) ) / sizeof(Vertex) ) / ctlg;
		

		//{ REQUESTS
		// Requests tot_requests = initialize_requests(requests);
		// Requests tot_requests = generate_requests(requests, alpha, ctlg, load);
		stringstream ssfilename; 
		ssfilename << "/home/andrea/software/araldo-phd-code/utility_based_caching/examples/multi_as/gap_0.01/int/fixed-power4/abilene/cache-constrained/ctlg-"<< ctlg<<"/c2ctlg-"<< c2ctlg <<
			"/alpha-"<<alpha <<"/load-"<< load
			<<"/strategy-RepresentationAware/seed-"<< seed <<"/req.dat";
		reqfilename = ssfilename.str().c_str() ;

		
		std::cout<<"reqfilename = "<< reqfilename << std::endl;
		//} REQUESTS

	} else if(argc==5)
	{
		// The demand is taken from the input file
		input = direct;
		reqfilename = argv[1];
		num_iterations = strtoul(argv[2], NULL, 0);
		slowdown = atoi(argv[3]);
		single_storage = atof(argv[4]);
		steps = parse_steps (argv[5]);
		
	}else
	{
		cout<<"usage: "<<argv[0]<<" <alpha> <ctlg> <load> <iterations> <seed> <slowdown> <single_storage> <steps>\n or"<<endl;
		cout<<"\t"<<argv[0]<<" <req_filename> <iterations> <slowdown> <single_storage> <steps>"<<endl;
		exit(1);
	}
	//} INPUT

	cout<<"eps "<<eps<<endl;
	Weight min_gross_utility = DBL_MAX;
	Weight max_tot_feasible_utility = 0;

	
	// Parameter for the step update
	unsigned M = num_iterations/(10);

	Requests tot_requests = load_requests(requests, reqfilename );

	//{ INITIALIZE INPUT DATA STRUCTURE
	vector<E> edges(edges_, edges_+sizeof(edges_)/sizeof(E) );
	vector<Size> tmp_sizevec(sizes, sizes+sizeof(sizes)/sizeof(Size)  );
	double avg_size = compute_norm(tmp_sizevec );
	Weight init_w=0/(tot_requests*avg_size); // Initialization weight
	vector<Weight>weights(sizeof(edges_)/sizeof(E), init_w);
	cout<<"weights: "; print_collection(weights);
	//} INITIALIZE INPUT DATA STRUCTURE

	Weight first_violation_norm=0;
	double first_step, old_step;
	for (unsigned k=1; k<=num_iterations; k++)
	{
		cout<<"\n\n################# ITER "<<k<<endl;
		cout<<"new_weights "; print_collection(weights);

		unsigned num_nodes = count_nodes(edges);
		Graph G(edges_, edges_ + sizeof(edges_)/sizeof(E), weights.data(), num_nodes);
		EdgeValues edge_weight_map;
		fill_weight_map(edge_weight_map, edges, weights, G);

		//{ COMPUTE THE UTILITY
		Weight tot_feasible_utility_cleaned, lagrangian_value;
		Weight tot_feasible_utility_cleaned_with_normalization = 0;
		Weight lagrangian_value_with_normalization = 0;
		Weight tot_feasible_utility_cleaned_without_normalization = 0;
		Weight lagrangian_value_without_normalization = 0;
		bool normalized;
		EdgeValues edge_load_map, edge_load_map_with_normalization, 
				edge_load_map_without_normalization;

		if (improved)
		{	// I also compute the solution without normalization of the benefit
			normalized=false;
			greedy(edge_load_map_without_normalization, edge_weight_map, edges, G, 
				tot_feasible_utility_cleaned_without_normalization, lagrangian_value_without_normalization,
				normalized, single_storage
			);
		}

		normalized = true;
		greedy(edge_load_map_with_normalization, edge_weight_map, edges, G, 
				tot_feasible_utility_cleaned_with_normalization, lagrangian_value_with_normalization,
				normalized, single_storage
			);


		if (!improved || 
			lagrangian_value_with_normalization >= lagrangian_value_without_normalization
		){
			normalized=true;
			lagrangian_value = lagrangian_value_with_normalization;
			tot_feasible_utility_cleaned = tot_feasible_utility_cleaned_with_normalization;
			edge_load_map = edge_load_map_with_normalization;
		}
		else{
			normalized=false;
			lagrangian_value = lagrangian_value_without_normalization;
			tot_feasible_utility_cleaned = tot_feasible_utility_cleaned_without_normalization;
			edge_load_map = edge_load_map_without_normalization;
		}
		//} COMPUTE THE UTILITY
		
	
		cout<<"edge_load_map: "; 	print_edge_load_map(edge_load_map);

		// Compute the violations
		vector<Weight> violations; violations.reserve(edges.size());
		for (unsigned eid=0; eid<edges.size(); eid++)
		{
			EdgeDescriptor e = edge(edges[eid].first, edges[eid].second ,G).first;
			violations[eid] = edge_load_map[e] - link_capacity;
			if (k==1) first_violation_norm += violations[eid]*violations[eid] ;
		}
		#ifdef SEVERE_DEBUG
			if (lagrangian_value<0)
			{
				stringstream os; os<<"lagrangian_value is "<<lagrangian_value<<
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
			if (steps == moderate)
			{
				double multiplier = pow( 1.0- 1.0/ (1.0+M+(k/slowdown)+1), 0.5+eps );
				cout << "multiplier "<<multiplier<<endl;
				step = old_step * multiplier;
			} else if (steps == triangle)
				step = first_step / (k/slowdown + 1);
			else throw invalid_argument("Step size incorrect");
		}
		old_step = step;
		cout <<"step "<<step<<endl;
		//} STEP SIZE

		//{ VIOLATIONS
		Weight tot_violations=0;
		cout<<"violations ";
		for (unsigned eid=0; eid<edges.size(); eid++)
		{
			Weight single_violation = violations[eid];
			if (single_violation > 0)
				tot_violations += single_violation;
			cout<< single_violation <<" ";
		}
		cout<<endl;
		cout << "tot_violation "<< tot_violations << endl;
		//} VIOLATION

		update_weights(weights, step, violations);
		if (lagrangian_value < min_gross_utility)
			min_gross_utility = lagrangian_value;
		if (tot_feasible_utility_cleaned > max_tot_feasible_utility)
			max_tot_feasible_utility = tot_feasible_utility_cleaned;

		cout<<"tot_requests "<<tot_requests<<endl;
		cout<<"current_lagrangian "<<lagrangian_value/tot_requests<<endl;
		cout<<"min_lagrangian "<<min_gross_utility/tot_requests<<endl;
		cout<<"current_avg_feasible_utility "<<tot_feasible_utility_cleaned/tot_requests<<endl;
		cout<<"max_avg_feasible_utility "<<max_tot_feasible_utility / tot_requests<<endl;


		//Implement the tilde{psi} di math_paper
	}
	return 0;
}
