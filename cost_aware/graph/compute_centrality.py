from graph_tool.all import *

g = load_graph("graphs_pictorical_from_dario/geant.dot")
vp, ep = graph_tool.centrality.betweenness(g)
# vp stores the betwennes centrality of each vertex
# For other centrality measures, see http://graph-tool.skewed.de/static/doc/centrality.html#graph_tool.centrality.betweennesshttp://graph-tool.skewed.de/static/doc/centrality.html#graph_tool.centrality.betweenness
print(vp)
type(vp)


