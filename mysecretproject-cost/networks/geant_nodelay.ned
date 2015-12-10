package networks;

network geant_nodelay_network extends base_network{

    parameters:
        //Number of ccn nodes
    	n = 22;

    connections allowunconnected:

	node[1].face++ <--> node[0].face++;
	node[10].face++ <--> node[9].face++;
	node[11].face++ <--> node[10].face++;
	node[12].face++ <--> node[11].face++;
	node[12].face++ <--> node[3].face++;
	node[12].face++ <--> node[9].face++;
	node[13].face++ <--> node[12].face++;
	node[14].face++ <--> node[13].face++;
	node[14].face++ <--> node[5].face++;
	node[15].face++ <--> node[1].face++;
	node[15].face++ <--> node[12].face++;
	node[15].face++ <--> node[14].face++;
	node[15].face++ <--> node[4].face++;
	node[16].face++ <--> node[14].face++;
	node[17].face++ <--> node[1].face++;
	node[17].face++ <--> node[15].face++;
	node[17].face++ <--> node[16].face++;
	node[18].face++ <--> node[14].face++;
	node[18].face++ <--> node[17].face++;
	node[18].face++ <--> node[4].face++;
	node[19].face++ <--> node[18].face++;
	node[2].face++ <--> node[1].face++;
	node[20].face++ <--> node[18].face++;
	node[20].face++ <--> node[19].face++;
	node[21].face++ <--> node[0].face++;
	node[21].face++ <--> node[14].face++;
	node[21].face++ <--> node[20].face++;
	node[21].face++ <--> node[4].face++;
	node[3].face++ <--> node[1].face++;
	node[3].face++ <--> node[2].face++;
	node[4].face++ <--> node[3].face++;
	node[5].face++ <--> node[3].face++;
	node[6].face++ <--> node[5].face++;
	node[7].face++ <--> node[4].face++;
	node[7].face++ <--> node[6].face++;
	node[8].face++ <--> node[7].face++;
	node[9].face++ <--> node[8].face++;

}
