FROM tcely/isc-kea:dependency-log4cplus AS log4cplus

FROM alpine AS builder

ARG KEA_VERSION=1.4.0-P1

COPY --from=log4cplus /usr/local /usr/local/

COPY kea-premium-*.tar.gz /usr/src/

RUN apk --update upgrade && \
    apk add bash ca-certificates curl && \
    apk add --virtual .build-depends \
        file gnupg g++ make autoconf automake libtool \
        boost-dev bzip2-dev libressl-dev sqlite-dev zlib-dev \
        cassandra-cpp-driver-dev mariadb-dev postgresql-dev python3-dev && \
    curl -sS -RL -O "https://ftp.isc.org/isc/kea/${KEA_VERSION}/kea-${KEA_VERSION}.tar.gz{,.sha512.asc}" && \
    mkdir -v -m 0700 -p /root/.gnupg && \
    gpg2 --no-options --verbose --keyid-format 0xlong --keyserver-options auto-key-retrieve=true \
        --verify kea-*.asc kea-*.tar.gz && \
    rm -rf /root/.gnupg *.asc && \
    tar -xpf "kea-${KEA_VERSION}.tar.gz" && \
    rm -f "kea-${KEA_VERSION}.tar.gz" && \
    ( \
        cd "kea-${KEA_VERSION}" && \
        if [ -f /usr/src/kea-premium-*.tar.gz ]; then \
            tar xf /usr/src/kea-premium-*.tar.gz && \
            autoreconf -i ; \
        fi && \
        ./configure --enable-shell \
            --with-mysql=/usr/bin/mysql_config \
            --with-pgsql=/usr/bin/pg_config && \
        make -j$(nproc) && \
        make install-strip \
    ) && \
    apk del --purge .build-depends && rm -rf /var/cache/apk/*

FROM alpine
LABEL maintainer="https://keybase.io/tcely"

RUN apk --update upgrade && \
    apk add bash ca-certificates curl less man procps \
        boost bzip2 libressl sqlite zlib \
        mariadb-client postgresql-libs python3 && \
    rm -rf /var/cache/apk/*

ENV PAGER less

COPY --from=builder /usr/local /usr/local/

EXPOSE 67/udp
EXPOSE 8080

ENTRYPOINT ["/usr/local/sbin/kea-dhcp4"]
CMD ["-c", "/usr/local/etc/kea/kea-dhcp4.conf"]

# docker run --net=host -v ${PWD}/kea-dhcp4.conf:/usr/local/etc/kea/kea-dhcp4.conf -it kea-dhcp:latest kea-dhcp4 -c /usr/local/etc/kea/kea-dhcp4.conf
