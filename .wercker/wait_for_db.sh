#!/bin/bash
set -e

CONNECTION_STR=$1

while ! exit | sql -S -L -nohistory -noupdates system/oracle@//$CONNECTION_STR > /dev/null; do
	echo Waiting for database to get ready...
	sleep 5
done
