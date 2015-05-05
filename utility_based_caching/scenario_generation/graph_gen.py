import igraph
import random
import numpy
import scipy.stats

size = 80 # number of nodes
m = 2


def generate_network_ned_file(my_seed):
	random.seed(my_seed)
	g = igraph.Graph.Barabasi(size,m)


	print   "graph ba"+str(my_seed)+" {"
	print   "	overlap=false;"
	print   "	splines=true;"
	print   "	node [shape=circle,style=filled,width=.1,height=.1,label=\"\"];"
	print   ""
	print   ""

	edgelist = g.get_edgelist()
	for edge in edgelist:
		print   "		n"+str(edge[0])+" -- n"+str(edge[1])
	print   "}"

	print "the nodes are ", g.vs ;
	print "the degree is ", 	g.degree();
	print "sorted degrees ", sorted(g.degree() ); 
	


my_seed = 1;
generate_network_ned_file(my_seed)

