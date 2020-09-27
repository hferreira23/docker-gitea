**Gitea Docker Container**

Built on alpine:edge with the latest release tag of Gitea.

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
