package modules.node.cache;

moduleinterface cache
{
    parameters:
	int C; 	//<aa> How many objects can be stored in the cache, supposing to store them at the
			//highest representation </aa>
	//<mt>
	int NC; 
	//</mt>

    gates:
	inout cache_port;
}

simple base_cache like cache
{
    parameters:
    	@display("i=block/buffer2;is=l");

	string DS = default("lce");
	int C;
	int NC = default(C); //name cache dimension (in case of two_lru)
    gates:
	inout cache_port;
}



simple random_cache extends base_cache{
    @class(random_cache);
}

simple lru_cache extends base_cache{
    @class(lru_cache);
}

simple two_cache extends base_cache{
    @class(two_cache);
}

simple fifo_cache extends base_cache{
    @class(fifo_cache);
}

//<aa>
simple lru_repr_cache extends lru_cache
{
    @class(lru_repr_cache);
}    

simple partitioned_cache extends base_cache{
    @class(partitioned_cache);
	string equality;
}
simple partitionedn_cache extends base_cache{
    @class(partitioned_cache);
	string equality="number_of_objects";
}

simple partitioneds_cache extends base_cache{
    @class(partitioned_cache);
	string equality="space";
}

simple always_highq_cache extends lru_cache{
    @class(always_highq_cache);
}
//</aa>
