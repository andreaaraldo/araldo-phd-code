package networks;
network ws9_network extends base_network{
    parameters:
        //Number of ccn nodes
    	n = 22;
		int priceratio;
		double kappa;
		int cachesize;
		int single_cachesize = ceil(cachesize / n );
		node[0..21].content_store.C = single_cachesize;

    connections allowunconnected:
    node[1].face++<--> {delay = 2.59ms; } <-->node[18].face++;
    node[2].face++<--> {delay = 2.59ms; } <-->node[13].face++;
    node[8].face++<--> {delay = 2.59ms; } <-->node[12].face++;
    node[3].face++<--> {delay = 2.59ms; } <-->node[4].face++;
    node[4].face++<--> {delay = 2.59ms; } <-->node[5].face++;
    node[1].face++<--> {delay = 2.59ms; } <-->node[5].face++;
    node[6].face++<--> {delay = 2.59ms; } <-->node[18].face++;
    node[7].face++<--> {delay = 2.59ms; } <-->node[8].face++;
    node[9].face++<--> {delay = 2.59ms; } <-->node[14].face++;
    node[9].face++<--> {delay = 2.59ms; } <-->node[10].face++;
    node[10].face++<--> {delay = 2.59ms; } <-->node[11].face++;
    node[11].face++<--> {delay = 2.59ms; } <-->node[12].face++;
    node[12].face++<--> {delay = 2.59ms; } <-->node[19].face++;
    node[7].face++<--> {delay = 2.59ms; } <-->node[14].face++;
    node[1].face++<--> {delay = 2.59ms; } <-->node[20].face++;
    node[15].face++<--> {delay = 2.59ms; } <-->node[16].face++;
    node[5].face++<--> {delay = 2.59ms; } <-->node[16].face++;
    node[17].face++<--> {delay = 2.59ms; } <-->node[18].face++;
    node[18].face++<--> {delay = 2.59ms; } <-->node[19].face++;
    node[14].face++<--> {delay = 2.59ms; } <-->node[19].face++;
    node[20].face++<--> {delay = 2.59ms; } <-->node[21].face++;
    node[2].face++<--> {delay = 2.59ms; } <-->node[21].face++;
    node[2].face++<--> {delay = 2.59ms; } <-->node[9].face++;
    node[3].face++<--> {delay = 2.59ms; } <-->node[20].face++;
    node[1].face++<--> {delay = 2.59ms; } <-->node[15].face++;
    node[7].face++<--> {delay = 2.59ms; } <-->node[16].face++;
    node[12].face++<--> {delay = 2.59ms; } <-->node[21].face++;
    node[3].face++<--> {delay = 2.59ms; } <-->node[15].face++;
    node[4].face++<--> {delay = 2.59ms; } <-->node[6].face++;
    node[5].face++<--> {delay = 2.59ms; } <-->node[14].face++;
    node[5].face++<--> {delay = 2.59ms; } <-->node[6].face++;
    node[0].face++<--> {delay = 2.59ms; } <-->node[7].face++;
    node[2].face++<--> {delay = 2.59ms; } <-->node[8].face++;
    node[4].face++<--> {delay = 2.59ms; } <-->node[9].face++;
    node[10].face++<--> {delay = 2.59ms; } <-->node[12].face++;
    node[11].face++<--> {delay = 2.59ms; } <-->node[21].face++;
    node[12].face++<--> {delay = 2.59ms; } <-->node[14].face++;
    node[5].face++<--> {delay = 2.59ms; } <-->node[15].face++;
    node[1].face++<--> {delay = 2.59ms; } <-->node[14].face++;
    node[15].face++<--> {delay = 2.59ms; } <-->node[17].face++;
    node[16].face++<--> {delay = 2.59ms; } <-->node[18].face++;
    node[12].face++<--> {delay = 2.59ms; } <-->node[17].face++;
    node[18].face++<--> {delay = 2.59ms; } <-->node[20].face++;
    node[19].face++<--> {delay = 2.59ms; } <-->node[21].face++;
}
//avg node degree: 4.0
//coefficient of variation of node degree: 0.369274472938
//diameter: 5
