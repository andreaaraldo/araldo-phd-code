exit;



#for k in abilene  qwest geant level3 dtelecom   tiger
for k in abilene  
do 
    #for j in dot neato circo fdp
    for j in neato fdp
    do
            $j -Tps -o${j}_$k.eps $k.dot
            $j -Tsvg -o${j}_$k.svg $k.dot
    done        
done 

