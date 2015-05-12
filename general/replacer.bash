#!/bin/bash

TEMPLATE_FILE=$1
# File in which you want to operate substitution


REPLACEMENT_RULE_FILE=$2 
# Each line of this file should be in the form
#	<placeholder> <value>
# The script will replace any occurrence of <key> of the template file with <value>

cp $TEMPLATE_FILE /tmp/prova_replacement.temp
while read LINE
do           
	PLACEHOLDER=`echo "$LINE" | cut -f1 -d' '`
	VALUE=`echo "$LINE" | cut -f2 -d' '`
	sed -i  's/'$PLACEHOLDER'/'$VALUE'/g' /tmp/prova_replacement.temp
done < $REPLACEMENT_RULE_FILE

cat /tmp/prova_replacement.temp
