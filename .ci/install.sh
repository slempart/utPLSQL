#!/bin/bash
set -e

cd $BASE_PATH/source
sqlplus $UT3_OWNER/$UT3_OWNER_PASSWORD@localhost:1521/$SID @install.sql $UT3_OWNER

cd $BASE_PATH/development
sqlplus $UT3_OWNER/$UT3_OWNER_PASSWORD@localhost:1521/$SID @utplsql_style_check.sql

cd $BASE_PATH/source
sqlplus $UT3_OWNER/$UT3_OWNER_PASSWORD@localhost:1521/$SID @create_synonyms_and_grants_for_user.sql $UT3_OWNER $UT3_USER
