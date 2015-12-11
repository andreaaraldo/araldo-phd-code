package networks;

network abilene_nodelay_network extends base_network{

    parameters:
        //Number of ccn nodes
    	n = 11;

		//<aa>
		//node[*].core_layer.interest_aggregation =  false; 
		//<aa>

connections allowunconnected:
	node[1].face++ <--> node[0].face++;
	node[10].face++ <--> node[0].face++;
	node[10].face++ <--> node[1].face++;
	node[10].face++ <--> node[9].face++;
	node[2].face++ <--> node[1].face++;
	node[3].face++ <--> node[2].face++;
	node[4].face++ <--> node[3].face++;
	node[5].face++ <--> node[4].face++;
	node[6].face++ <--> node[5].face++;
	node[7].face++ <--> node[3].face++;
	node[7].face++ <--> node[6].face++;
	node[8].face++ <--> node[2].face++;
	node[8].face++ <--> node[7].face++;
	node[9].face++ <--> node[8].face++;
}
