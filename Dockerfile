FROM debian:bookworm-slim as builder
ARG CABAL_VERSION=3.6.2.0
ARG GHC_VERSION=8.10.7

WORKDIR /code

# system dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && \
  apt-get install -y \
    automake \
    build-essential \
    pkg-config \
    libffi-dev \
    libgmp-dev \
    liblmdb-dev \
    libnuma-dev \
    libssl-dev \
    libsystemd-dev \
    libtinfo-dev \
    llvm-dev \
    zlib1g-dev \
    make \
    g++ \
    tmux \
    git \
    jq \
    wget \
    libncursesw5 \
    libtool \
    autoconf

# cabal
ENV CABAL_VERSION=${CABAL_VERSION}
ENV PATH="/root/.cabal/bin:/root/.ghcup/bin:/root/.local/bin:$PATH"
RUN wget https://downloads.haskell.org/~cabal/cabal-install-${CABAL_VERSION}/cabal-install-${CABAL_VERSION}-$(uname -m)-linux-deb10.tar.xz \
    && tar -xf cabal-install-${CABAL_VERSION}-$(uname -m)-linux-deb10.tar.xz \
    && rm cabal-install-${CABAL_VERSION}-$(uname -m)-linux-deb10.tar.xz \
    && mkdir -p ~/.local/bin \
    && mv cabal ~/.local/bin/ \
    && cabal update && cabal --version

# GHC
ENV GHC_VERSION=${GHC_VERSION}
RUN wget https://downloads.haskell.org/~ghc/${GHC_VERSION}/ghc-${GHC_VERSION}-$(uname -m)-deb10-linux.tar.xz \
    && tar -xf ghc-${GHC_VERSION}-$(uname -m)-deb10-linux.tar.xz \
    && rm ghc-${GHC_VERSION}-$(uname -m)-deb10-linux.tar.xz \
    && cd ghc-${GHC_VERSION} \
    && ./configure \
    && make install

# Libsodium
RUN git clone https://github.com/input-output-hk/libsodium && \
    cd libsodium && \
    git checkout dbb48cce && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

# secp256k1
RUN git clone https://github.com/bitcoin-core/secp256k1 && \
    cd secp256k1 && \
    git checkout ac83be33 && \
    ./autogen.sh && \
    ./configure --enable-module-schnorrsig --enable-experimental && \
    make && \
    make install

FROM builder as haskell
