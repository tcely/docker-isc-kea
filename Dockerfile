ARG KEA_VERSION=1.4.0-P1

FROM tcely/isc-kea:dependency-log4cplus AS log4cplus

FROM alpine AS builder

ARG KEA_VERSION

COPY --from=log4cplus /usr/local /usr/local/

COPY cql_config /usr/local/bin/cql_config

RUN apk --update upgrade && \
    apk add bash ca-certificates curl && \
    apk add --virtual .build-depends \
        file gnupg g++ make \
        boost-dev bzip2-dev openssl-dev sqlite-dev zlib-dev \
        cassandra-cpp-driver-dev mariadb-dev postgresql-dev python3-dev && \
    curl -RL -O "https://ftp.isc.org/isc/kea/${KEA_VERSION}/kea-${KEA_VERSION}.tar.gz{,.sha512.asc}" && \
    mkdir -v -m 0700 -p /root/.gnupg && \
    gpg2 --no-options --verbose --keyid-format 0xlong --keyserver-options auto-key-retrieve=true \
        --verify kea-*.asc kea-*.tar.gz && \
    rm -rf /root/.gnupg *.asc && \
    tar -xpf "kea-${KEA_VERSION}.tar.gz" && \
    rm -f "kea-${KEA_VERSION}.tar.gz" && \
    ( \
        cd "kea-${KEA_VERSION}" && \
        ./configure \
            --enable-shell \
            --with-cql=/usr/local/bin/cql_config \
            --with-dhcp-mysql=/usr/bin/mysql_config \
            --with-dhcp-pgsql=/usr/bin/pg_config && \
        make -j 4 && \
        make install-strip \
    ) && \
    apk del --purge .build-depends && rm -rf /var/cache/apk/*

FROM alpine
LABEL maintainer="https://keybase.io/tcely"

RUN apk --update upgrade && \
    apk add bash ca-certificates curl less man procps \
        boost bzip2 openssl sqlite zlib \
        cassandra-cpp-driver mariadb-client-libs postgresql-libs python3 && \
    rm -rf /var/cache/apk/*

ENV PAGER less

COPY --from=builder /usr/local /usr/local/

ENTRYPOINT ["/usr/local/sbin/kea-dhcp4"]
CMD ["-c", "/usr/local/etc/kea/kea-dhcp4.conf"]
