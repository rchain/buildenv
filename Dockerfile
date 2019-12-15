# Temporary container for building BNFC
FROM haskell:8 as bnfc-build
RUN cabal update
RUN cabal install happy alex
WORKDIR /var/tmp/bnfc
ARG BNFC_COMMIT=ce7fe1fd08d9d808c14ff626c321218c5b73e38b
RUN git clone https://github.com/BNFC/bnfc . && git checkout $BNFC_COMMIT
RUN stack init && stack setup
RUN stack build && stack install --local-bin-path=.

# Container for building RChain
# bionic = 18.04
FROM ubuntu:bionic
COPY --from=bnfc-build /var/tmp/bnfc/bnfc /usr/local/bin/
RUN apt update && apt install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates curl \
        gnupg \
        lsb-release \
        locales \
        git \
        python3 \
        python3-pip \
        rpm \
        fakeroot \
        lintian
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && echo 'deb https://dl.bintray.com/sbt/debian /' >/etc/apt/sources.list.d/sbt.list \
    && echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >/etc/apt/sources.list.d/docker-ce.list
ENV LC_ALL en_US.UTF-8
RUN apt update && apt install -y --no-install-recommends \
        openjdk-11-jdk-headless \
        java-common \
        jflex \
        sbt=1.\* \
        docker-ce-cli
# sbt --version >/dev/null
#   Workaround bug in current sbt. See https://github.com/sbt/sbt-launcher-package/blob/aa6ce25a865632c628e0986c7204d419f086152d/src/universal/bin/sbt
#   lines 378 and 341. The execRunner call never returns, so the very
#   first run of sbt just says "Copying runtime jar." and exits. This
#   command should be removed when it's fixed in sbt as it will then
#   download full sbt runtime that will most likely differ from that
#   defined in RChain project (sbt.properties).
RUN sbt --version
WORKDIR /work
