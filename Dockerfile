# Temporary container for building BNFC
FROM haskell:8 as bnfc-build
RUN cabal update
RUN cabal install happy alex
WORKDIR /var/tmp/bnfc
ARG BNFC_COMMIT=ce7fe1fd08d9d808c14ff626c321218c5b73e38b
RUN git clone https://github.com/BNFC/bnfc . && git checkout $BNFC_COMMIT
RUN stack init
RUN stack setup
RUN stack build
RUN stack install --local-bin-path=_build

# Container for building RChain
# bionic = 18.04
FROM ubuntu:bionic
COPY --from=bnfc-build /var/tmp/bnfc/_build/bnfc /usr/local/bin/
RUN apt update
RUN apt install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates curl \
    gnupg \
    lsb-release
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && echo 'deb https://dl.bintray.com/sbt/debian /' >/etc/apt/sources.list.d/sbt.list \
    && echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >/etc/apt/sources.list.d/docker-ce.list
RUN apt update
RUN apt install -y --no-install-recommends \
    locales \
    git \
    java-common \
    jflex \
    openjdk-11-jdk-headless \
    openjdk-8-jdk-headless \
    sbt=1.\* \
    python3 \
    python3-pip \
    docker-ce \
    rpm \
    fakeroot \
    lintian
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen
ENV LC_ALL en_US.UTF-8
RUN curl -s https://codecov.io/bash >/usr/local/bin/codecov && chmod +x /usr/local/bin/codecov
WORKDIR /work
