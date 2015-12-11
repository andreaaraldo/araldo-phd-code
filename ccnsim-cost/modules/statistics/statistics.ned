package modules.statistics;
simple statistics{
    parameters:
		// Look also at the record_cache_value constant in statistics.h

		double ts = default(0.1);
		double window = default (60);
		double steady = default(1000);
		double partial_n = default(10);
		//<aa>
		double variance_threshold = default(0.05);
		string runid;
		double cache_dump_interval = default(0);
		//</aa>

		int CEXPL = default(3);
		double ttl = default(30);
		@display("i=block/table2;is=l");

}
