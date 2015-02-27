#!/bin/bash

OUTPUT_FOLDER="~/shared_with_servers/icn14_runs/greedy_algo";
LOG_FILE=$OUTPUT_FOLDER/run-`date "+%Y-%m-%d_%Hh%M.%S"`.log
SCRIPT_BACKUP_FILE="$LOG_FILE.m"
echo "log file: "$LOG_FILE
echo "script backup file: "$SCRIPT_BACKUP_FILE
octave --quiet run_numerical_results.m >& $LOG_FILE 2>&1

