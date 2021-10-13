# Build stage for BerkeleyDB
FROM ubuntu as berkeleydb

RUN apt-get update --fix-missing

RUN apt-get install -y wget 
RUN apt-get install -y build-essential 

ENV BERKELEYDB_VERSION=db-4.8.30.NC
ENV BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

RUN update-ca-certificates -f
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
FROM ubuntu as vertcoin-core

RUN apt-get update

RUN apt-get install -y git
RUN apt-get install -y build-essential
RUN apt-get install -y libzmq3-dev
RUN apt-get install -y autotools-dev
RUN apt-get install -y automake
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y pkg-config
RUN apt-get install -y libtool
RUN apt-get install -y libboost-all-dev
RUN apt-get install -y libssl-dev
RUN apt-get install -y libevent-dev
RUN apt-get install -y bsdmainutils
RUN apt-get install -y python3
RUN apt-get install -y libgmp-dev

COPY --from=berkeleydb /opt /opt

ENV VERTCOIN_VERSION=0.17.1
ENV VERTCOIN_PREFIX=/opt/vertcoin-${VERTCOIN_VERSION}

RUN git clone https://github.com/vertcoin-project/vertcoin-core.git /vertcoin-${VERTCOIN_VERSION} \
    && cd /vertcoin-${VERTCOIN_VERSION} \
    && git checkout ${VERTCOIN_VERSION}

WORKDIR /vertcoin-${VERTCOIN_VERSION}

# RUN sed -i '/AC_PREREQ/a\AR_FLAGS=cr' src/univalue/configure.ac
# RUN sed -i '/AX_PROG_CC_FOR_BUILD/a\AR_FLAGS=cr' src/secp256k1/configure.ac
# RUN sed -i s:sys/fcntl.h:fcntl.h: src/compat.h
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
FROM ubuntu

RUN apt-get update --fix-missing
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
RUN apt-get install -y libzmq3-dev
RUN apt-get install -y libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev
RUN apt-get install -y libevent-dev 
RUN apt-get install -y curl libgmp-dev

# Install latest su-exec
RUN  set -ex; \
     \
     curl -o /usr/local/bin/su-exec.c https://raw.githubusercontent.com/ncopa/su-exec/master/su-exec.c; \
     \
     fetch_deps='gcc libc-dev'; \
     apt-get update; \
     apt-get install -y --no-install-recommends $fetch_deps; \
     rm -rf /var/lib/apt/lists/*; \
     gcc -Wall \
         /usr/local/bin/su-exec.c -o/usr/local/bin/su-exec; \
     chown root:root /usr/local/bin/su-exec; \
     chmod 0755 /usr/local/bin/su-exec; \
     rm /usr/local/bin/su-exec.c; \
     \
     apt-get purge -y --auto-remove $fetch_deps

ENV VERTCOIN_USERNAME=vertcoin

RUN useradd -r "${VERTCOIN_USERNAME}"

ENV VERTCOIN_DATA="/home/${VERTCOIN_USERNAME}/.${VERTCOIN_USERNAME}"
ENV VERTCOIN_VERSION=0.17.1
ENV VERTCOIN_PREFIX=/opt/vertcoin-${VERTCOIN_VERSION}
ENV PATH=${VERTCOIN_PREFIX}/bin:$PATH

COPY --from=vertcoin-core /opt /opt
COPY docker-entrypoint.sh /entrypoint.sh

VOLUME ["/home/${VERTCOIN_USERNAME}/.${VERTCOIN_USERNAME}"]

EXPOSE 0 1 

RUN ["chmod", "+x", "/entrypoint.sh"]

ENTRYPOINT ["/entrypoint.sh"]

RUN vertcoind -version | grep "Vertcoin Core version v${VERTCOIN_VERSION}"

CMD ["vertcoind"]
