package networks;

network video_simple_scenario_network extends base_network
{

    parameters:
        //Number of ccn nodes
    	n = 2;
    	
    	int C;

	//Number of repositories
	num_repos = 1;
	node_repos = "0";
	replicas = 1;

	//Number of clients 
	num_clients = 1;
	node_clients = "1";
	
	client_type = "RepresentationAwareClient";
	node[0].content_store.C = 0;
	node[1].content_store.C = C;


connections:
    node[0].face++ <--> node[1].face++;

    
}
