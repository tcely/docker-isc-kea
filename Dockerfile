ARG KEA_VERSION=1.3.0

FROM alpine AS builder

ARG KEA_VERSION
ARG EXTRA_KEY

RUN apk --update upgrade && \
    apk add ca-certificates curl && \
    apk add --virtual .build-depends \
      file gnupg g++ make \
      boost-dev libressl-dev libsodium-dev lua-dev net-snmp-dev protobuf-dev \
      libedit-dev re2-dev && \
    curl -RL -O "https://ftp.isc.org/isc/kea/${KEA_VERSION}/kea-${KEA_VERSION}.tar.gz{,.sha512.asc}" && \
    curl -RL -o SigningKeys 'https://www.isc.org/about/openpgp' && \
    sed -i -e 's/^<pre>//' SigningKeys && \
    mkdir -v -m 0700 -p /root/.gnupg && \
    gpg2 --no-options --verbose --keyid-format 0xlong --import SigningKeys && rm -f SigningKeys && \
    ( [ -z "${EXTRA_KEY}" ] || gpg2 --no-options --verbose --keyid-format 0xlong --recv-key "${EXTRA_KEY}" ) && \
    gpg2 --no-options --verbose --keyid-format 0xlong --verify kea-*.asc kea-*.tar.gz && \
    rm -rf /root/.gnupg *.asc && \
    tar -xvvpf "kea-${KEA_VERSION}.tar.gz" && \
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
        boost libressl libsodium lua net-snmp protobuf \
        libedit re2 && \
    rm -rf /var/cache/apk/*

ENV PAGER less

RUN addgroup -S dnsdist && \
    adduser -S -D -G dnsdist dnsdist

#COPY --from=builder /usr/local/bin /usr/local/bin/
#COPY --from=builder /usr/share/man/man1 /usr/share/man/man1/

#ENTRYPOINT ["/usr/local/bin/dnsdist"]
#CMD ["--help"]
