#!/bin/bash
set -e

CONNECTION_STR=$ORACLEDB_PORT_1521_TCP_ADDR:1521/$1

sql -S -L -nohistory -noupdates /NOLOG <<EOF
whenever sqlerror exit failure rollback
whenever oserror exit failure rollback

conn $UT3_OWNER/$UT3_OWNER_PASSWORD@//$CONNECTION_STR
@examples/RunAllExamplesAsTests.sql

conn $UT3_USER/$UT3_USER_PASSWORD@//$CONNECTION_STR
@examples/RunUserExamples.sql

conn $UT3_OWNER/$UT3_OWNER_PASSWORD@//$CONNECTION_STR
@tests/RunAll.sql

exit;
EOF
