#!/bin/bash
set -e

cd $BASE_PATH/examples
echo "Running examples as user..."
sqlplus $UT3_USER/$UT3_USER_PASSWORD@localhost:1521/$SID @RunAllExamplesAsTests.sql

cd $BASE_PATH/tests
echo "Running tests as user..."
sqlplus $UT3_USER/$UT3_USER_PASSWORD@localhost:1521/$SID @RunAll.sql
