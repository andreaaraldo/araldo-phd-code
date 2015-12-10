package networks;

import modules.node.node;

network cost_scenario_network extends base_network
{
    parameters:
		// n[0] is the caching node. The client is attached to n[0]. The nodes n[1], n[2] and n[3]
		// are not caching nodes. They serve only as attachement points for repositories.
		// Consider them as "fake" nodes or "transparent nodes".

		// The free  (price=0), cheap (price=1) and expensive (price=priceratio) repositories
		// are randomly choses among the three repositories.
		// To understand how their prices are intitialized, see 
		//			WeightedContentDistribution::init_repo_prices()
		
		int priceratio;
		double kappa;
		int cachesize;


    	n = 4;
		num_clients = 1;
		node_clients = "0";
		num_repos = 3;
		node_repos = "1,2,3";
		content_distribution_type = "WeightedContentDistribution";
		content_distribution.priceratio = priceratio;
		content_distribution.kappa = kappa;  // Costaware exponent (see costaware_policy.h)

		double cheap_price = 1;
		double expensive_price = priceratio;

		node[0].content_store.C =  cachesize;


		// The following nodes are not working as caching nodes, they are here only to have
		// a repository attached
		node[1].content_store.C =  0;
		node[1].core_layer.interest_aggregation =  false; 
		node[1].core_layer.transparent_to_hops = true;
		node[2].content_store.C =  0;
		node[2].core_layer.interest_aggregation =  false; 
		node[2].core_layer.transparent_to_hops = true;
		node[3].content_store.C =  0;
		node[3].core_layer.interest_aggregation =  false; 
		node[3].core_layer.transparent_to_hops = true;



    connections allowunconnected :
    	//Remember that the first port of each node is connected to a client (see networks/base.ned),
    	// even if the client is not active
        node[0].face++ <--> node[1].face++;
        node[0].face++ <--> node[2].face++;
        node[0].face++ <--> node[3].face++;
}
