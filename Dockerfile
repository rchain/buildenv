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
RUN apt update \
    && apt install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        locales \
        lsb-release \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && echo 'deb https://dl.bintray.com/sbt/debian /' >/etc/apt/sources.list.d/sbt.list \
    && echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >/etc/apt/sources.list.d/docker-ce.list \
    && echo 'deb https://packages.cloud.google.com/apt cloud-sdk main' >/etc/apt/sources.list.d/google-cloud-sdk.list
ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 PYENV_ROOT=/opt/pyenv
RUN apt update \
    && apt install -y --no-install-recommends \
        build-essential \
        docker-ce-cli \
        fakeroot \
        git \
        google-cloud-sdk \
        java-common \
        jflex \
        jq \
        libbz2-dev \
        libffi-dev \
        liblzma-dev \
        libsqlite3-dev \
        libssl-dev \
        lintian \
        moreutils \
        openjdk-8-jdk-headless \
        openjdk-11-jdk-headless \
        python-crcmod \
        python3 \
        python3-pip \
        rpm \
        sbt=1.\* \
        zlib1g-dev \
    && update-java-alternatives --set java-1.11.0-openjdk-amd64 \
    && pip3 install -U setuptools pip \
    && hash -r \
    && pip3 install -U \
        pipenv \
        pyyaml \
        requests \
    && curl -fsSL https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash \
    && for dir in \
        /tmp \
        /var/cache \
        /var/lib/apt/lists \
        /var/tmp \
        ~/.cache \
        ; do [ ! -d $dir ] || find $dir -mindepth 1 -delete; done
ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
COPY --from=bnfc-build /var/tmp/bnfc/bnfc /usr/local/bin/
WORKDIR /work
# Workaround bug in current sbt. See https://github.com/sbt/sbt-launcher-package/blob/aa6ce25a865632c628e0986c7204d419f086152d/src/universal/bin/sbt
# lines 378 and 341. The execRunner call never returns, so the very first run
# of sbt just says "Copying runtime jar." and exits. This command should be
# removed when it's fixed in sbt as it will then download full sbt runtime that
# will most likely differ from that defined in RChain project (sbt.properties).
RUN sbt --version
