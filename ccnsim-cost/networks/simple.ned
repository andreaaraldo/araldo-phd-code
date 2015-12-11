package networks;

import modules.node.node;

network simple_network extends base_network
{
    parameters:
		// n[0] is the caching node. The client is attached to n[0]. The node 1 is not a 
		// caching node. It is only an attachement point for the repository
		// Consider it as "fake" node or "transparent node".

		int cachesize;


	    	n = 2;
		num_clients = 1;
		node_clients = "0";
		num_repos = 1;
		node_repos = "1";


		// The following nodes are not working as caching nodes, they are here only to have
		// a repository attached
		node[1].content_store.C =  0;


    connections allowunconnected :
    	//Remember that the first port of each node is connected to a client (see networks/base.ned),
    	// even if the client is not active
        node[0].face++ <--> node[1].face++;
}
