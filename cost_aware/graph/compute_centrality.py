from graph_tool.all import *

g = load_graph("graphs_pictorical_from_dario/geant.dot")
vp, ep = graph_tool.centrality.betweenness(g, norm=False)
# vp stores the betwennes centrality of each vertex
# For other centrality measures, see http://graph-tool.skewed.de/static/doc/centrality.html#graph_tool.centrality.betweennesshttp://graph-tool.skewed.de/static/doc/centrality.html#graph_tool.centrality.betweenness

for v in g.vertices():
	print(v.in_degree() )
	print(v.out_degree() )

