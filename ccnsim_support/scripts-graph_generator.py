import igraph
import random
import numpy
import scipy.stats

dim=1 #dimension of the starting lattice (for ws only)
N = size = 100 # number of nodes
K = nei = 2 #  (for ws only)
beta = p = 0.4 # rewiring probability  (for ws only)
loops=False #  (for ws only)
multiple=False #  (for ws only)
networks=range(1,2); # how many networks do you want to generate?

def convert_to_ned(g, name):
	folder='/tmp'
	nedfile = folder+"/"+name+".ned"
	f1=open(nedfile, 'w')

	print >>f1, "package networks;"

	print >>f1, "network "+name+"_network extends base_network{"
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

	# edge_expr = "<--> {delay = 2.59ms; } <-->"
	edge_expr = "<-->"
	edgelist = g.get_edgelist()
	for edge in edgelist:
		print >>f1, "    node[" + str(edge[0] ) +"].face++" + edge_expr + "node["+str( edge[1] ) +"].face++;"

	print >>f1, "}"

	print >>f1, "//avg node degree: "+ str( numpy.mean( g.degree() ) )
	print >>f1, "//coefficient of variation of node degree: "+str ( scipy.stats.variation( g.degree() ) )
	print >>f1, "//diameter: "+ str( igraph.Graph.diameter(g) )
	print "file "+nedfile + " generated"


def convert_to_dot(g, name):
	folder='/tmp'
	dotfile = folder+'/'+name+'.dot'
	fdot=open(dotfile,'w')

	print >>fdot, "graph "+name+" {"
	print >>fdot, "	overlap=false;"
	print >>fdot, "	splines=true;"
	print >>fdot, "	node [shape=circle,style=filled,width=.1,height=.1,label=\"\"];"
	print >>fdot, ""
	print >>fdot, ""

	edgelist = g.get_edgelist()
	for edge in edgelist:
		print >>fdot, "		n"+str(edge[0])+" -- n"+str(edge[1])

	print >>fdot, "}"

	print "file "+dotfile + " generated"

# Watts-Strogatz graph generator
def generate_ws(my_seed):
	random.seed(my_seed)
	g = igraph.Graph.Watts_Strogatz(dim,size,nei,p,loops,multiple)
	name = "ws"+str(my_seed)
	convert_to_ned(g,name)
	convert_to_dot(g,name)

# Barabasi-Albert graph generator
def generate_ba(my_seed):
	random.seed(my_seed)
	g = igraph.Graph.Barabasi(N)
	name = "barabasi"+str(my_seed)
	convert_to_ned(g,name)
	convert_to_dot(g,name)

for i in networks:
	generate_ba(i)

