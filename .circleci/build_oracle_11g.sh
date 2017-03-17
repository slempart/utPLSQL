#!bin/bash
set -e

if [ -f $CACHE_DIR/oracle-11g.tar.gz ]; then
    echo "Oracle 11g is already cached, nothing to do..."
    exit 0
fi

ORACLE11g_FILE=oracle-xe-11.2.0-1.0.x86_64.rpm.zip

# Download Oracle 11g Install Files
cd ./.circleci
bash download.sh -p xe11g
mv $ORACLE11g_FILE ./dockerfiles/11.2.0.2

# Create Swap
df -B1 /dev/shm | awk 'END { if ($1 != "shmfs" && $1 != "tmpfs" || $2 < 2147483648) exit 1 }' ||
  ( rm -r /dev/shm && mkdir /dev/shm && mount -t tmpfs shmfs -o size=2G /dev/shm )

# Build and Save Docker image
cd ./dockerfiles/11.2.0.2
docker build -f Dockerfile.xe --no-cache=true --force-rm=true -t oracle-11g-install .
docker run -d --privileged --shm-size=1g --name oracle-11g-install -p 1521:1521 oracle-11g-install
docker logs -f oracle-11g-install | grep -m 1 "DATABASE IS READY TO USE!" --line-buffered
docker exec oracle-11g-install ./setPassword.sh oracle
docker stop oracle-11g-install
docker commit oracle-11g-prebuilt
docker save oracle-11g-prebuilt > ~/utplsql/.cache/oracle-11g.tar
docker rm oracle-11g-install
docker rmi oracle-11g-prebuilt
docker rmi oracle-11g-install
