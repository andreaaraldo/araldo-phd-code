package modules.clients;


simple client like IClient
{
    parameters:
    	@display("i=abstract/people;is=l");
    	double lambda = default(1);
		double W = default(1); //TODO
		double check_time = default(0.1);
		double RTT = default(0.1);
	gates:
    	inout client_port;
}

// This is not a real client; It is a proactive component of a node,
// i.e. a component of a node that decides to send interests in order to
// improve the cache content
simple ProactiveComponent extends client
{
	parameters:
	    @class(ProactiveComponent);
		lambda = 0; // It does not spontanously send interests
		double proactive_probability=default(1);
}

simple RepresentationAwareClient extends client
{
	parameters:
		@class(RepresentationAwareClient);
}

