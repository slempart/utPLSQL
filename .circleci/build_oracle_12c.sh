#!bin/bash
set -e

if [ -f $CACHE_DIR/oracle-12c.tar.gz ]; then
    echo "Oracle 12c is already cached, nothing to do..."
    exit 0
fi

ORACLE12c_FILE1=linuxamd64_12102_database_se2_1of2.zip
ORACLE12c_FILE2=linuxamd64_12102_database_se2_2of2.zip

# Download Oracle 12c Install Files
cd ./.circleci
bash download.sh -p se12c
mv $ORACLE12c_FILE1 ./dockerfiles/12.1.0.2
mv $ORACLE12c_FILE2 ./dockerfiles/12.1.0.2

# Build and Save Docker image
cd ./dockerfiles/12.1.0.2
docker build -f Dockerfile.se2 --no-cache=true --force-rm=true -t oracle-12c-install .
docker run -d --privileged --name oracle-12c-install -p 1521:1521 oracle-12c-install
docker logs -f oracle-12c-install | grep -m 1 "DATABASE IS READY TO USE!" --line-buffered
docker exec oracle-12c-install ./setPassword.sh oracle
docker stop oracle-12c-install
docker commit oracle-12c-prebuilt
docker save oracle-12c-prebuilt > ~/utplsql/.cache/oracle-12c.tar
docker rm oracle-12c-install
docker rmi oracle-12c-prebuilt
docker rmi oracle-12c-install
