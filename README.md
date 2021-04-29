**Gitea Docker Container**

Daily build of Gitea on alpine:edge with the latest master commits.

Suported archs: amd64, arm7, arm64.

Docker Compose example

```yaml
version: "3.8"
services:
  gitea:
    container_name: gitea
    image: hferreira/gitea:latest
    ports:
      - "3000:3000"
    ports:
      - "2222:22"
    volumes:
      - /opt/gitea/:/data
    restart: unless-stopped
```

Docker Hub: https://hub.docker.com/r/hferreira/gitea
