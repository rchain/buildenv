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
        ca-certificates \
        curl \
        gnupg \
        jq \
        lsb-release \
        locales \
        git \
        rpm \
        fakeroot \
        lintian
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && echo 'deb https://dl.bintray.com/sbt/debian /' >/etc/apt/sources.list.d/sbt.list \
    && echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >/etc/apt/sources.list.d/docker-ce.list
ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
RUN apt update && apt install -y --no-install-recommends \
        openjdk-11-jdk-headless \
        java-common \
        jflex \
        sbt=1.\* \
        docker-ce-cli
ARG PYTHON_VERSION=3.7.3
ARG PYTHON_BUILDREQ="\
    build-essential \
    libbz2-dev \
    libffi-dev \
    liblzma-dev \
    libsqlite3-dev \
    libssl-dev \
    make \
    zlib1g-dev \
"
ARG PYENV_GITREV=master
ENV PYENV_ROOT=/opt/pyenv
ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
RUN apt install -y --no-install-recommends $PYTHON_BUILDREQ \
    && curl -fsSL https://raw.githubusercontent.com/pyenv/pyenv-installer/$PYENV_GITREV/bin/pyenv-installer | bash \
    && pyenv install $PYTHON_VERSION \
    && rm -r $PYENV_ROOT/versions/*/lib/python*/test \
    && find $PYENV_ROOT -name '*.exe' -exec rm {} \; \
    && pyenv global $PYTHON_VERSION \
    && python -m pip install pipenv \
    && apt purge -y --auto-remove $PYTHON_BUILDREQ
COPY bin/* /usr/local/bin/
RUN rm -rf /var/cache/* \
    && mkdir /var/cache/sbt /var/cache/ivy2 \
    && rm -rf ~/.cache/* /tmp/* /var/tmp/* /var/lib/apt/lists/*
ENV SBT_OPTS="-Dsbt.global.base=/var/cache/sbt -Dsbt.ivy.home=/var/cache/ivy2"
WORKDIR /work
# sbt --version >/dev/null
#   Workaround bug in current sbt. See https://github.com/sbt/sbt-launcher-package/blob/aa6ce25a865632c628e0986c7204d419f086152d/src/universal/bin/sbt
#   lines 378 and 341. The execRunner call never returns, so the very
#   first run of sbt just says "Copying runtime jar." and exits. This
#   command should be removed when it's fixed in sbt as it will then
#   download full sbt runtime that will most likely differ from that
#   defined in RChain project (sbt.properties).
RUN sbt --version
