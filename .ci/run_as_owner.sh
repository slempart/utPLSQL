#!/bin/bash
set -e

cd $BASE_PATH/examples
echo "Running examples as owner..."
sqlplus $UT3_OWNER/$UT3_OWNER_PASSWORD@localhost:1521/$SID @RunAllExamplesAsTests.sql

cd $BASE_PATH/tests
echo "Running tests as owner..."
sqlplus $UT3_OWNER/$UT3_OWNER_PASSWORD@localhost:1521/$SID @RunAll.sql
