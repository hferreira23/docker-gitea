**Gitea Docker Container**

Daily build of Gitea on alpine:edge with the latest master commits.

This container uses the rootless gitea dockerfile as a base.

Suported archs: amd64, arm7, arm64.

Basic Docker Compose example

```yaml
version: "3.9"
services:
  gitea:
    container_name: gitea
    image: hferreira/gitea:latest
    ports:
      - "3000:3000"
    ports:
      - "2222:22"
    volumes:
      - /opt/gitea/:/var/lib/gitea
      - /opt/gitea/conf/app.ini:/etc/gitea/app.ini
    restart: unless-stopped
```

Docker Hub: https://hub.docker.com/r/hferreira/gitea

[![gitea_ci](https://github.com/hferreira23/docker-gitea/actions/workflows/image.yml/badge.svg?branch=master)](https://github.com/hferreira23/docker-gitea/actions/workflows/image.yml)
