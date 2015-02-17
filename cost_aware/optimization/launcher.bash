#!/bin/bash

############################################################
########### THIS CODE IS OLD AND IT IS NO MORE USED ########
########### SEE run.m for the new version ##################
############################################################

WORKING_FOLDER=~/globecom14_working_folder
OPTIMIZATION_OUTPUT_FOLDER=$WORKING_FOLDER/optimization_output
SCENARIO_FOLDER=$WORKING_FOLDER/scenarios

CODE_FOLDER=~/code
THIS_LAUNCHER=$CODE_FOLDER/optimization/launcher.bash
GENERATION_CODE=$CODE_FOLDER/optimization/scenario_generation/build_run.m
HIDE_OUTPUT="false" # Use "false" during debug operations. Use "true" if you use screen.
OPT_PROCESSOR="wishset" # it can be "wishset" or "oplrun"


for SEED in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
do
	for ALPHA in 0 0.8 1 1.2
	do
		for TOTALDEMAND in 180000
		do
			for MODEL in "model_ideal_cost" #"model_ideal_hitratio" "model_lfu_hitratio" "model_lfu_costhitratio"
			do
				for CATALOG_SIZE in 1e5
				do
					for MAX_CACHE in 0 1e3 #1e2 #1e3 1e4 1e5
					do
						for PRICE_RATIO in 1 2 5 10
						do
							# Fixing stuff for scenario generation
							SCENARIO_IDENTIFIER="ctlg_"$CATALOG_SIZE"-cache_"$MAX_CACHE"-priceratio_"$PRICE_RATIO"-seed_"$SEED"-totaldemand_"$TOTALDEMAND"-alpha_"$ALPHA
							SCENARIO_PREFIX=$SCENARIO_FOLDER/scenario-$SCENARIO_IDENTIFIER
							GENERATION_LOG=$SCENARIO_PREFIX.generation.log
							GENERATION_TIME_LOG=$SCENARIO_PREFIX.generation_time.log
							SCENARIO_FILE=$SCENARIO_PREFIX.dat
							SCENARIO_FILE="" # In this way we won't generate the dat file
							SCENARIO_GENERATION_COMMAND="build_run(\"$SCENARIO_FILE\",$CATALOG_SIZE, $MAX_CACHE, $PRICE_RATIO, $SEED, $TOTALDEMAND, $ALPHA)"


							# Fixing stuff for OPL runs
							SCENARIO_OPTIMIZATION_OUTPUT_FOLDER=$OPTIMIZATION_OUTPUT_FOLDER/$OPT_PROCESSOR-$MODEL-$SCENARIO_IDENTIFIER
							MODELFILE=$MODEL".mod"
							OPTRUN_LOG=$SCENARIO_OPTIMIZATION_OUTPUT_FOLDER/oplrun.log
							OPTRUN_TIME_LOG=$SCENARIO_OPTIMIZATION_OUTPUT_FOLDER/oplrun_time.log
							GENERAL_LOG=$SCENARIO_OPTIMIZATION_OUTPUT_FOLDER/general.log

							
							if [[ "$HIDE_OUTPUT" == "false" ]]; then
								# All log output must be redirected on the screen
								GENERATION_LOG="1"
								GENERATION_TIME_LOG="1"
								OPTRUN_LOG="1"
								OPTRUN_TIME_LOG="1"
								GENERAL_LOG="1"
							fi


							# Fixing stuff for wishset runs
							OPTIMIZATION_DIMENSION=""
							if [[ "$MODEL" == "model_ideal_cost" ]]; then
								OPTIMIZATION_DIMENSION="cost"
							elif [[ "$MODEL" == "model_ideal_hitratio" ]]; then
								OPTIMIZATION_DIMENSION="hitratio"
							else
								echo "I cannot realize what is the optimization dimension ">& $GENERAL_LOG
								exit 1
							fi

							WISHSET_COMMAND="run_wishset_algo(\"$SCENARIO_FILE\",\"$SCENARIO_OPTIMIZATION_OUTPUT_FOLDER\",\"$OPTIMIZATION_DIMENSION\",$SEED)"


							if [ -d "$SCENARIO_OPTIMIZATION_OUTPUT_FOLDER" ]; then
									echo "$SCENARIO_OPTIMIZATION_OUTPUT_FOLDER" >& $GENERAL_LOG
									echo " I have already executed this run. I will not execute it."  >& $GENERAL_LOG
									echo "I will reuse the existing output " >& $GENERAL_LOG
									echo "" >& $GENERAL_LOG
									continue
							fi

							#else
							mkdir -p $SCENARIO_OPTIMIZATION_OUTPUT_FOLDER

							# Generate scenario if not yet generated
							if [ -f "$SCENARIO_FILE" ]; then
								echo "Scenario $SCENARIO_FILE already generated. I will reuse it"  >& $GENERAL_LOG
							else
								echo "Generating scenario $SCENARIO_IDENTIFIER"
								{ time octave --quiet --path $CODE_FOLDER/optimization/scenario_generation/ --eval "$SCENARIO_GENERATION_COMMAND" >& $GENERATION_LOG; } 2>& $GENERATION_TIME_LOG
							fi


							# Verify if the scenario has been correctly generated
							if [ -f "$SCENARIO_FILE" ]; then
								echo ""
							else
								echo "There is no sceneario file $SCENARIO_FILE" >& $GENERAL_LOG
								echo "Open $GENERATION_LOG to see what happened"
							fi


							# {Launch optimization
								if [[ "$OPT_PROCESSOR" == "oplrun" ]]; then
									{ time oplrun $MODELFILE $SCENARIO_FILE >& $OPTRUN_LOG; } 2>& $OPTRUN_TIME_LOG

								elif [[ "$OPT_PROCESSOR" == "wishset" ]]; then
									{ time octave --quiet --path $CODE_FOLDER/wishset --eval "$WISHSET_COMMAND" >& $OPTRUN_LOG; } 2>& $OPTRUN_TIME_LOG

								else
									echo "I cannot realize what is the optimization processor "$OPT_PROCESSOR > $GENERAL_LOG
									exit 1
								fi

								# Check the exit status $?
								if [[ $? != 0 ]]; then
									echo "There is an error"
									exit $?
								fi
							# }Launch optimization
							

							# Move the results
							mv *csv $SCENARIO_OPTIMIZATION_OUTPUT_FOLDER
							cp $MODELFILE $SCENARIO_OPTIMIZATION_OUTPUT_FOLDER
							cp $GENERATION_CODE $SCENARIO_OPTIMIZATION_OUTPUT_FOLDER
							cp $THIS_LAUNCHER $SCENARIO_OPTIMIZATION_OUTPUT_FOLDER
							cp $SCENARIO_PREFIX.* $SCENARIO_OPTIMIZATION_OUTPUT_FOLDER
						done # PRICE_RATIO loop
					done # MAX_CACHE loop
				done # CATALOG_SIZE loop
			done # MODEL loop
		done # TOTALDEMAND loop
	done #ALPHA loop
done # SEED loop
