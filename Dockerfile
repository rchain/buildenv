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
COPY init-buildenv /tmp/
RUN /tmp/init-buildenv
ENV LC_ALL en_US.UTF-8
WORKDIR /work
