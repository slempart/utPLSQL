#!/bin/bash
set -e

cd $BASE_PATH/.ci

echo "Creating utPLSQL users..."
sqlplus sys/oracle@localhost:1521/$SID as sysdba <<SQL
set echo off
@@create_utplsql_owner.sql $UT3_OWNER $UT3_OWNER_PASSWORD $UT3_OWNER_TABLESPACE
@@create_utplsql_user.sql $UT3_USER $UT3_USER_PASSWORD $UT3_USER_TABLESPACE
SQL
