#!/usr/bin/Rscript
args <- commandArgs(TRUE);

if(length( args )!= 3 )
	stop("correct usage:\n\t tree.r <children> <height> <capacity>")

children = as.numeric(args[1] ); # number of nodes
height = as.numeric(args[2] ); # does not take into account the root
capacity = as.numeric(args[3] ); # link capacity

suppressPackageStartupMessages(library("igraph") ) 

size = floor( ( children**(height+1) - 1 ) / (children-1) );
g <- graph.tree(size, children, mode="out" );

indegreelist <- degree(g, mode="in");
root <- which( indegreelist == 0 );
#{CHECK
	if (length(root)!=1 )
	{
		print ("More than one root was found");
		quit(1);
	}
#}CHECK
cat(root,"\n");

outdegreelist <- degree(g, mode="out");
leaves <- which( outdegreelist == 0 );
cat(leaves,"\n");


link_str = "{";
for (e in E(g))
{
	verts = get.edge(g, e);
	link_str = sprintf("%s,<%d,%d,%d>", link_str, verts[1],verts[2], capacity );
}
link_str = sprintf("%s };", link_str);
link_str <- sub('\\{,', "{ ", link_str);
cat(link_str,"\n")
