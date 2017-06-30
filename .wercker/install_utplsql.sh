#!/bin/bash
set -e

CONNECTION_STR=$ORACLEDB_PORT_1521_TCP_ADDR:1521/$1

bash .wercker/wait_for_db.sh $CONNECTION_STR
sql -S -L -nohistory -noupdates /NOLOG <<EOF
set feedback off
set verify off

conn sys/oracle@//$CONNECTION_STR AS SYSDBA
@source/create_utplsql_owner.sql $UT3_OWNER $UT3_OWNER_PASSWORD $UT3_TABLESPACE
-- Needed for mystats script to work.
grant select any dictionary to $UT3_OWNER;
-- Needed for testing a coverage outside ut3_owner.
grant create any procedure, execute any procedure to $UT3_OWNER;

@source/create_utplsql_owner.sql $UT3_USER $UT3_USER_PASSWORD $UT3_TABLESPACE

-- Enable plsql debug.
-- @development/ut_debug_enable.sql

@source/install.sql $UT3_OWNER
@source/create_synonyms_and_grants_for_user.sql $UT3_OWNER $UT3_USER

conn $UT3_OWNER/$UT3_OWNER_PASSWORD@//$CONNECTION_STR
@development/utplsql_style_check.sql

exit
EOF
