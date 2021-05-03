###################################
#Build stage
FROM golang:alpine AS build-env

ARG GOPROXY
ENV GOPROXY ${GOPROXY:-direct}

ARG GITEA_VERSION
ARG TAGS="sqlite sqlite_unlock_notify"
ENV TAGS "bindata $TAGS"
ARG CGO_EXTRA_CFLAGS

#Build deps
RUN apk --no-cache add build-base git nodejs npm openssh

#Setup repo
WORKDIR /go
RUN git clone --depth 1 https://github.com/go-gitea/gitea.git

#Checkout version if set
WORKDIR /go/gitea
RUN if [ -n "${GITEA_VERSION}" ]; then git checkout "${GITEA_VERSION}"; fi && \
    make clean-all build

# Begin env-to-ini build
RUN go build contrib/environment-to-ini/environment-to-ini.go

FROM alpine:edge
LABEL maintainer="Hugo Ferreira"

EXPOSE 22 3000

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk update && \
    apk upgrade --available && \
    apk --update add \
    bash \
    ca-certificates \
    gettext \
    git \
    gnupg && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

RUN addgroup \
    -S -g 2001 \
    git && \
    adduser \
    -S -H -D \
    -h /var/lib/gitea/git \
    -s /bin/bash \
    -u 2001 \
    -G git \
    git

RUN mkdir -p /var/lib/gitea /etc/gitea
RUN chown git:git /var/lib/gitea /etc/gitea

COPY --from=build-env --chown=root:root /go/gitea/docker/rootless /
COPY --from=build-env --chown=root:root /go/gitea/gitea /usr/local/bin/gitea
COPY --from=build-env --chown=root:root /go/gitea/environment-to-ini /usr/local/bin/environment-to-ini

USER git:git
ENV GITEA_WORK_DIR /var/lib/gitea
ENV GITEA_CUSTOM /var/lib/gitea/custom
ENV GITEA_TEMP /tmp/gitea
#TODO add to docs the ability to define the ini to load (usefull to test and revert a config)
ENV GITEA_APP_INI /etc/gitea/app.ini
ENV HOME "/var/lib/gitea/git"
VOLUME ["/var/lib/gitea", "/etc/gitea"]
WORKDIR /var/lib/gitea

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD []
