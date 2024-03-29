###################################
#Build stage
FROM golang:1.17-alpine3.13 AS build-env

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

RUN apk --no-cache add \
    bash \
    ca-certificates \
    gettext \
    git \
    curl \
    gnupg && \
    apk --no-cache upgrade --available

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
COPY --from=build-env --chown=root:root /go/gitea/gitea /app/gitea/gitea
COPY --from=build-env --chown=root:root /go/gitea/environment-to-ini /usr/local/bin/environment-to-ini
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-setup.sh /app/gitea/gitea /usr/local/bin/gitea /usr/local/bin/environment-to-ini

USER git:git
ENV GITEA_WORK_DIR /var/lib/gitea
ENV GITEA_CUSTOM /var/lib/gitea/custom
ENV GITEA_TEMP /tmp/gitea
ENV TMPDIR /tmp/gitea

#TODO add to docs the ability to define the ini to load (usefull to test and revert a config)
ENV GITEA_APP_INI /etc/gitea/app.ini
ENV HOME "/var/lib/gitea/git"
VOLUME ["/var/lib/gitea", "/etc/gitea"]
WORKDIR /var/lib/gitea

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD []
