ARG KEA_VERSION=1.3.0
ARG BOTAN_VERSION=2.4.0
ARG LOG4CPLUS_VERSION=1.2.1-rc2

FROM alpine AS builder

ARG KEA_VERSION
ARG BOTAN_VERSION
ARG LOG4CPLUS_VERSION

RUN apk --update upgrade && \
    apk add ca-certificates curl && \
    apk add --virtual .build-depends \
      file gnupg g++ make \
      boost-dev libressl-dev \
      mariadb-dev postgresql-dev python3-dev && \
    curl -RL -O "https://ftp.isc.org/isc/kea/${KEA_VERSION}/kea-${KEA_VERSION}.tar.gz{,.sha512.asc}" && \
    curl -RLJ -O "https://botan.randombit.net/releases/Botan-${BOTAN_VERSION}.tgz{.asc,}" && \
    curl -RLJ -O "https://sourceforge.net/projects/log4cplus/files/log4cplus-stable/${LOG4CPLUS_VERSION}/log4cplus-${LOG4CPLUS_VERSION}.tar.gz{.sig,}/download" && \
    ls -al && \
    mkdir -v -m 0700 -p /root/.gnupg && \
    gpg2 --no-options --verbose --keyserver-options auto-key-retrieve=true --keyid-format 0xlong --verify Botan-*.asc Botan-*.tgz && \
    gpg2 --no-options --verbose --keyserver-options auto-key-retrieve=true --keyid-format 0xlong --verify log4cplus-*.sig log4cplus-*.tar.gz && \
    gpg2 --no-options --verbose --keyserver-options auto-key-retrieve=true --keyid-format 0xlong --verify kea-*.asc kea-*.tar.gz && \
    rm -rf /root/.gnupg *.asc && \
    tar -xvvpf "Botan-${BOTAN_VERSION}.tgz" && \
    rm -f "Botan-${BOTAN_VERSION}.tgz" && \
    ( \
        cd "Botan-${BOTAN_VERSION}" && \
        ./configure.py && \
        make -j 2 && \
        make install \
    ) && \
    tar -xpf "log4cplus-${LOG4CPLUS_VERSION}.tar.gz" && \
    rm -f "log4cplus-${LOG4CPLUS_VERSION}.tar.gz" && \
    ( \
        cd "log4cplus-${LOG4CPLUS_VERSION}" && \
        ./configure && \
        make && \
        make install \
    ) && \
    tar -xpf "kea-${KEA_VERSION}.tar.gz" && \
    rm -f "kea-${KEA_VERSION}.tar.gz" && \
    ( \
        cd "kea-${KEA_VERSION}" && \
        ./configure && \
        make -j 2 && \
        make install-strip \
    ) && \
    apk del --purge .build-depends && rm -rf /var/cache/apk/*

FROM alpine
LABEL maintainer="https://keybase.io/tcely"

RUN apk --update upgrade && \
    apk add ca-certificates curl less man \
        boost libressl \
        mariadb-libs postgresql-libs python3 && \
    rm -rf /var/cache/apk/*

ENV PAGER less

RUN addgroup -S dnsdist && \
    adduser -S -D -G dnsdist dnsdist

#COPY --from=builder /usr/local/bin /usr/local/bin/
#COPY --from=builder /usr/share/man/man1 /usr/share/man/man1/

#ENTRYPOINT ["/usr/local/bin/dnsdist"]
#CMD ["--help"]
