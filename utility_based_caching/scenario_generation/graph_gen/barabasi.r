#!/usr/bin/Rscript
args <- commandArgs(TRUE);

if(length( args )!= 4 )
	stop("correct usage:\n\t barabasi.r <size> <tier3_cardinality> <capacity> <topology_seed>")

size = as.numeric(args[1] ); # number of nodes
tier3_cardinality = as.numeric(args[2] );
capacity = as.numeric(args[3] ); # link capacity
topology_seed = as.numeric(args[4] ); # link capacity

suppressPackageStartupMessages(library("igraph") ) 

set.seed(topology_seed);
g <- barabasi.game(size, directed=FALSE);
V(g)$name <- V(g);
sortedDegrees <- sort(degree(g) );
sortedVertexIDs <- attr(sortedDegrees, "names", exact=TRUE);

tier3_nodes = sortedVertexIDs[1:tier3_cardinality];
#core_nodes = sortedVertexIDs[(size-core_cardinality+1):size] #useless
cat(tier3_nodes,"\n")

link_str = "{";
for (e in E(g))
{
	verts = get.edge(g, e);
	link_str = sprintf("%s,<%d,%d,%d>, <%d,%d,%d>", link_str, verts[1],verts[2], capacity,verts[2],verts[1], capacity );
}
link_str = sprintf("%s };", link_str);
link_str <- sub('\\{,', "{ ", link_str);
cat(link_str,"\n")
