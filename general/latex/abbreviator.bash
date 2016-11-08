F=$1 #filename
sed -i 's/{~}/~/g' $F
sed -i 's/{\\_}/\_/g' $F
sed -i 's/Journal\ on\ Selected\ Areas\ in\ Communications/JSAC/g' $F
sed -i 's/Springer\ Science\ and\ Business\ Media/Springer/g' $F
sed -i 's/IEEE\ Communications\ Magazine/IEEE\ Commun.\ Mag./g' $F
sed -i 's/ACM\ Transactions\ on\ Computer\ Systems\ (TOCS)/ACM\ Trans.\ Comput.\ Syst./g' $F
sed -i 's/Security\ and\ Privacy\ in\ Communication\ Networks/Security\ Privacy\ \ Commun.\ Netw./g' $F
sed -i 's/ACM Workshop on Information-centric networking/ACM\ ICN\ Workshop/g' $F
sed -i 's/Computer Networks/Comput. Netw./g' $F
sed -i 's/Computer Communications/Comput. Comm./g' $F
sed -i 's/IFIP Networking/IFIP Netw./g' $F
sed -i 's/IEEE Transactions on Parallel and Distributed Systems/IEEE Trans. Parallel Distrib. Syst./g' $F

