                  / _____)_	      
  ____ ____ ____ ( (____ (_)_ __ ___  
 / ___) ___)  _ \ \____ \| | '_ ` _ \ 
( (__( (___| | | |_____) | | | | | | |
 \____)____)_| |_(______/|_|_| |_| |_|


Thank you for joining the ccnSim community!
This is ccnSim v0.3

You can freely download ccnSim from the project site: http://www.enst.fr/~drossi/ccnSim .

To install ccnSim, please follow the instructions on the manual, Section "Downloading and installing ccnSim" .

To run your first simulation
	./ccnSim -u Cmdenv

At the end, you will find different output files for different values of alpha and different decision policies
	cat results/abilene/F-spr/D-{decision}/R-lru/alpha-{alpha_value}/ccn-id0.sca 

where {alpha_value} can be 0.5, 0.6, 0.7, 0.8, 0.9 or 1 and {decision} can be fix0.1, lcd, lce, prob_cache.

For more details, please refer to the manual
