package modules.node;


moduleinterface Inode
{
    parameters:
	string RS;
	string FS;

	int level;
	double betweenness;
	
	//<aa>if yes, the cache can store a chunk that is served by the attached repo
	bool cache_if_in_repo; 
	//</aa>

    gates:
	inout face[];	
	inout client_port;

}

