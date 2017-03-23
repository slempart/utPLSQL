# Base Dockerfile for codeship.

FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -y curl python && \
    # Node & Dependencies
    # curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
    # apt-get install -y nodejs build-essential libfontconfig && \
    # npm install -g phantomjs-prebuilt casperjs && \
    # Java
    # apt-get install -y software-properties-common && \
    # add-apt-repository -y ppa:webupd8team/java && apt-get update && \
    # apt-get install -y oracle-java8-installer && \
    # apt-get install -y oracle-java8-set-default && \
    # Clean
    apt-get clean

ADD . /app
