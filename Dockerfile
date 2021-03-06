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
RUN apk --no-cache add build-base git nodejs npm openssh bash

#Define Shell
SHELL ["/bin/bash", "-c"]

#Setup repo
WORKDIR /go
RUN git clone --depth 1 https://github.com/go-gitea/gitea.git

#Checkout version if set
WORKDIR /go/gitea
RUN latestTag=$(git rev-list --tags --max-count=1) && \
    if [ -n "${latestTag}" ]; then git checkout "${latestTag}"; fi && \
    make clean-all build

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
    curl \
    gettext \
    git \
    hub \
    linux-pam \
    openssh \
    s6 \
    sqlite \
    su-exec \
    tzdata \
    gnupg && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

RUN addgroup \
    -S -g 2001 \
    git && \
    adduser \
    -S -H -D \
    -h /data/git \
    -s /bin/bash \
    -u 2001 \
    -G git \
    git && \
  echo "git:$(dd if=/dev/urandom bs=24 count=1 status=none | base64)" | chpasswd

ENV USER git
ENV GITEA_CUSTOM /data/gitea

VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/bin/s6-svscan", "/etc/s6"]

COPY --from=build-env /go/gitea/docker/root /
COPY --from=build-env /go/gitea/gitea /app/gitea/gitea
RUN ln -s /app/gitea/gitea /usr/local/bin/gitea
