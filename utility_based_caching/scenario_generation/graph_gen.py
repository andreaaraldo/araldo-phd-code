import igraph
import random
import numpy
import scipy.stats

size = 22 # number of nodes
m = 2


beta = p = 0.4
networks=range(5,22); # how many networks do you want to generate?


def generate_network_ned_file(my_seed):
	random.seed(my_seed)
	g = igraph.Graph.Barabasi(size,m)

	folder='/tmp'
	nedfile = folder+'/ws'+str(my_seed)+'.ned'
	dotfile = folder+'/ws'+str(my_seed)+'.dot'
	f1=open(nedfile, 'w')
	fdot=open(dotfile,'w')

	print >>f1, "package networks;"

	print >>f1, "network ws"+str(my_seed)+"_network extends base_network{"
	print >>f1, "    parameters:"
	print >>f1, "        //Number of ccn nodes"
	print >>f1, "    	n = "+str(g.vcount() )+";"
	print >>f1, "		int priceratio;"
	print >>f1, "		double kappa;"
	print >>f1, "		int cachesize;"
	print >>f1, "		int single_cachesize = ceil(cachesize / n );"
	print >>f1, "		node[0..21].content_store.C = single_cachesize;"
	print >>f1, ""
	print >>f1, "    connections allowunconnected:"

	print >>fdot, "graph ws"+str(my_seed)+" {"
	print >>fdot, "	overlap=false;"
	print >>fdot, "	splines=true;"
	print >>fdot, "	node [shape=circle,style=filled,width=.1,height=.1,label=\"\"];"
	print >>fdot, ""
	print >>fdot, ""

	edgelist = g.get_edgelist()
	for edge in edgelist:
		print >>f1, "    node[" + str(edge[0] ) +"].face++" + "<--> {delay = 2.59ms; } <-->" + "node["+str( edge[1] ) +"].face++;"
		print >>fdot, "		n"+str(edge[0])+" -- n"+str(edge[1])

	print >>f1, "}"
	print >>fdot, "}"

	print >>f1, "//avg node degree: "+ str( numpy.mean( g.degree() ) )
	print >>f1, "//coefficient of variation of node degree: "+str ( scipy.stats.variation( g.degree() ) )
	print >>f1, "//diameter: "+ str( igraph.Graph.diameter(g) )
	print "file "+nedfile + " generated"
	print "file "+dotfile + " generated"
	layout = g.layout_kamada_kawai()


for i in networks:
	generate_network_ned_file(i)

