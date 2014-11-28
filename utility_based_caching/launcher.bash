#!/bin/bash

############################################################
########### THIS CODE IS OLD AND IT IS NO MORE USED ########
########### SEE run.m for the new version ##################
############################################################

WORKING_FOLDER=/tmp/utility_runs
OPTIMIZATION_OUTPUT_FOLDER=$WORKING_FOLDER/optimization_output
SCENARIO_FOLDER=$WORKING_FOLDER/scenarios
mkdir -p $SCENARIO_FOLDER
mkdir -p $OPTIMIZATION_OUTPUT_FOLDER

CODE_FOLDER=~/software/araldo-phd-code
THIS_LAUNCHER=$CODE_FOLDER/utility_based_caching/launcher.bash
GENERATION_CODE=$CODE_FOLDER/utility_based_caching/scenario_generation/build_run.m

HIDE_OUTPUT="false" # Use "false" during debug operations. Use "true" if you use screen.
OPT_PROCESSOR="oplrun" #must be oplrun
OPTIMIZATION_DIMENSION="utility"


for SEED in 1
do
	for ALPHA in 1
	do
		for TOTALDEMAND in 180000
		do
			for MODEL in "model"
			do
				for CATALOG_SIZE in 10
				do
					for MAX_CACHE in 0
					do
						for PRICE_RATIO in 1
						do
							# Fixing stuff for scenario generation
							SCENARIO_IDENTIFIER="ctlg_"$CATALOG_SIZE"-cache_"$MAX_CACHE"-priceratio_"$PRICE_RATIO"-seed_"$SEED"-totaldemand_"$TOTALDEMAND"-alpha_"$ALPHA
							SCENARIO_PREFIX=$SCENARIO_FOLDER/scenario-$SCENARIO_IDENTIFIER
							GENERATION_LOG=$SCENARIO_PREFIX.generation.log
							GENERATION_TIME_LOG=$SCENARIO_PREFIX.generation_time.log
							SCENARIO_FILE=$SCENARIO_PREFIX.dat # If it is equal to "" we won't generate the dat file
							SCENARIO_GENERATION_COMMAND="build_run(\"$SCENARIO_FILE\",$CATALOG_SIZE, $MAX_CACHE, $PRICE_RATIO, $SEED, $TOTALDEMAND, $ALPHA)"


							# Fixing stuff for OPL runs
							SCENARIO_OPTIMIZATION_OUTPUT_FOLDER=$OPTIMIZATION_OUTPUT_FOLDER/$OPT_PROCESSOR-$MODEL-$SCENARIO_IDENTIFIER
							MODELFILE=$MODEL".mod"
							OPTRUN_LOG=$SCENARIO_OPTIMIZATION_OUTPUT_FOLDER/oplrun.log
							OPTRUN_TIME_LOG=$SCENARIO_OPTIMIZATION_OUTPUT_FOLDER/oplrun_time.log
							GENERAL_LOG=$SCENARIO_OPTIMIZATION_OUTPUT_FOLDER/general.log

							
							if [[ "$HIDE_OUTPUT" == "false" ]]; then
								# All log output must be redirected on the screen
								GENERATION_LOG=/dev/stdout
								GENERATION_TIME_LOG=/dev/stdout
								OPTRUN_LOG=/dev/stdout
								OPTRUN_TIME_LOG=/dev/stdout
								GENERAL_LOG=/dev/stdout
							fi



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
								{ time octave --quiet --path $CODE_FOLDER/utility_based_caching/scenario_generation/ --eval "$SCENARIO_GENERATION_COMMAND" >& $GENERATION_LOG; } 2> $GENERATION_TIME_LOG
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
									echo "Launching oplrun"
									{ time oplrun $MODELFILE $SCENARIO_FILE >& $OPTRUN_LOG; } 2> $OPTRUN_TIME_LOG
							else
									echo "I cannot realize what the optimization processor "$OPT_PROCESSOR" is" > $GENERAL_LOG
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
