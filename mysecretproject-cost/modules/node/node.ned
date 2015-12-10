package modules.node;
import modules.node.strategy.*;
import modules.node.cache.*;
import modules.node.Inode;
import modules.clients.ProactiveComponent;


module node like Inode{
    parameters:
	string RS = default("lru_cache");
	string FS = default("spr");

	int level = default (-1);
	double betweenness = default (-1);
	content_store.DS = default("lce");
	
	//<aa>if yes, the cache can store a chunk that is served by the attached repo
	bool cache_if_in_repo = default(true); 
	//</aa>
	

	@display("i=abstract/router;is=s");
    gates:
		inout face[];	
		inout client_port;

    submodules:
		core_layer : core_layer;
		strategy_layer : < "modules.node.strategy." + FS > like strategy;
		content_store : < "modules.node.cache." + RS > like cache;
		proactive_component : ProactiveComponent;

    connections :
		core_layer.face++ <--> proactive_component.client_port;

		for i=0..sizeof(face)-1{
			core_layer.face++ <--> face [i];
		}

		core_layer.client_port <--> client_port;
		core_layer.cache_port  <--> content_store.cache_port;
		core_layer.strategy_port <--> strategy_layer.strategy_port;
}

