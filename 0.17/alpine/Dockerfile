# Build stage for BerkeleyDB
FROM alpine as berkeleydb

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add autoconf
RUN apk --no-cache add automake
RUN apk --no-cache add build-base
RUN apk --no-cache add libressl

ENV BERKELEYDB_VERSION=db-4.8.30.NC
ENV BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

RUN wget https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz
RUN tar -xzf *.tar.gz
RUN sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ${BERKELEYDB_VERSION}/dbinc/atomic.h
RUN mkdir -p ${BERKELEYDB_PREFIX}

WORKDIR /${BERKELEYDB_VERSION}/build_unix

RUN ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELEYDB_PREFIX}
RUN make -j`nproc`
RUN make install
RUN rm -rf ${BERKELEYDB_PREFIX}/docs

# Build stage for Vertcoin Core
FROM alpine as vertcoin-core

COPY --from=berkeleydb /opt /opt

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add autoconf
RUN apk --no-cache add automake
RUN apk --no-cache add boost-dev
RUN apk --no-cache add build-base
RUN apk --no-cache add chrpath
RUN apk --no-cache add file
RUN apk --no-cache add gnupg
RUN apk --no-cache add libevent-dev
RUN apk --no-cache add libressl
RUN apk --no-cache add libtool
RUN apk --no-cache add linux-headers
RUN apk --no-cache add zeromq-dev
RUN apk --no-cache add git
RUN apk --no-cache add openssl-dev
RUN apk --no-cache add gmp-dev

ENV VERTCOIN_VERSION=0.17.1
ENV VERTCOIN_PREFIX=/opt/vertcoin-${VERTCOIN_VERSION}

RUN git clone https://github.com/vertcoin-project/vertcoin-core.git /vertcoin-${VERTCOIN_VERSION} \
    && cd /vertcoin-${VERTCOIN_VERSION} \
    && git checkout ${VERTCOIN_VERSION}

WORKDIR /vertcoin-${VERTCOIN_VERSION}

RUN sed -i '/AC_PREREQ/a\AR_FLAGS=cr' src/univalue/configure.ac
RUN sed -i '/AX_PROG_CC_FOR_BUILD/a\AR_FLAGS=cr' src/secp256k1/configure.ac
RUN sed -i s:sys/fcntl.h:fcntl.h: src/compat.h
RUN ./autogen.sh

RUN ./configure LDFLAGS=-L`ls -d /opt/db*`/lib/ CPPFLAGS=-I`ls -d /opt/db*`/include/ \
    --prefix=${VERTCOIN_PREFIX} \
    --mandir=/usr/share/man \
    --disable-tests \
    --disable-bench \
    --disable-ccache \
    --with-gui=no \
    --with-utils \
    --with-libs \
    --with-daemon
RUN make -j`nproc`
RUN make install
RUN strip ${VERTCOIN_PREFIX}/bin/vertcoin-cli
# RUN strip ${VERTCOIN_PREFIX}/bin/vertcoin-tx
RUN strip ${VERTCOIN_PREFIX}/bin/vertcoind
# RUN strip ${VERTCOIN_PREFIX}/lib/libbitcoinconsensus.a
# RUN strip ${VERTCOIN_PREFIX}/lib/libbitcoinconsensus.so.0.0.0

# Build stage for compiled artifacts
FROM alpine

RUN adduser -S vertcoin
RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add \
  boost-filesystem \
  boost-system \
  boost-thread \
  boost-chrono \
  libevent \
  libzmq \
  su-exec \
  gmp

ENV VERTCOIN_DATA=/home/vertcoin/.vertcoin
ENV VERTCOIN_VERSION=0.17.1
ENV VERTCOIN_PREFIX=/opt/vertcoin-${VERTCOIN_VERSION}
ENV PATH=${VERTCOIN_PREFIX}/bin:$PATH

COPY --from=vertcoin-core /opt /opt
COPY docker-entrypoint.sh /entrypoint.sh

VOLUME ["/home/vertcoin/.vertcoin"]

EXPOSE 0 1 

RUN ["chmod", "+x", "/entrypoint.sh"]

ENTRYPOINT ["/entrypoint.sh"]

RUN vertcoind -version | grep "Vertcoin Core version v${VERTCOIN_VERSION}"

CMD ["vertcoind"]
