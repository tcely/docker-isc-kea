ARG LOG4CPLUS_VERSION=2.0.2

FROM alpine AS builder

ARG LOG4CPLUS_VERSION

RUN apk --update upgrade && \
    apk add ca-certificates curl && \
    apk add --virtual .build-depends \
      file gnupg g++ make \
      && \
    curl -RLJ -O "https://sourceforge.net/projects/log4cplus/files/log4cplus-stable/${LOG4CPLUS_VERSION%%-*}/log4cplus-${LOG4CPLUS_VERSION}.tar.gz{.sig,}/download" && \
    mkdir -v -m 0700 -p /root/.gnupg && \
    gpg2 --no-options --verbose --keyserver-options auto-key-retrieve=true --keyid-format 0xlong --verify log4cplus-*.sig log4cplus-*.tar.gz && \
    rm -rf /root/.gnupg *.asc && \
    tar -xpf "log4cplus-${LOG4CPLUS_VERSION}.tar.gz" && \
    rm -f "log4cplus-${LOG4CPLUS_VERSION}.tar.gz" && \
    ( \
        cd "log4cplus-${LOG4CPLUS_VERSION}" && \
        ./configure && \
        make -j 2 && \
        make install-strip \
    ) && \
    apk del --purge .build-depends && rm -rf /var/cache/apk/*

FROM alpine
LABEL maintainer="https://keybase.io/tcely"

RUN apk --update --no-cache add less && \
    rm -rf /var/cache/apk/*

ENV PAGER less

COPY --from=builder /usr/local/include /usr/local/include/
COPY --from=builder /usr/local/lib /usr/local/lib/

ENTRYPOINT ["/bin/ls"]
CMD ["-alR", "/usr/local"]
