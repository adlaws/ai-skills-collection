---
name: docker-expert
description: 'Expert skill for creating, maintaining, and troubleshooting Docker containers, images, Dockerfiles, and Docker Compose configurations. Use when asked to write or review Dockerfiles, debug container issues, optimize image builds, configure docker-compose.yml files, diagnose networking or volume problems, fix container startup failures, or follow Docker best practices. Handles multi-stage builds, layer caching, security hardening, health checks, resource limits, and compose service orchestration.'
---

# Docker Expert

A skill for creating, maintaining, analysing, and troubleshooting Docker containers, images, Dockerfiles, and Docker Compose configurations. Provides practical, constructive solutions grounded in current best practices.

## When to Use This Skill

- Writing or reviewing Dockerfiles or docker-compose.yml files
- Debugging container build failures, startup issues, or runtime errors
- Optimising Docker image size, build speed, or layer caching
- Diagnosing networking, volume, or permission problems in containers
- Hardening container security (non-root users, minimal base images, secrets management)
- Configuring health checks, resource limits, restart policies, or logging
- Understanding Docker concepts or behaviour in plain terms
- Migrating from older Docker practices to modern best practices

## Communication Style

- **Default**: Provide concise, plain-language explanations that do not assume deep Docker internals knowledge. Focus on what is happening, why it matters, and how to fix it.
- **When asked for more detail**: Give in-depth explanations covering the underlying Docker mechanisms (union filesystems, namespaces, cgroups, networking stack, etc.).
- Always provide actionable solutions — not just descriptions of problems.

## Dockerfile Best Practices

Follow these practices when writing or reviewing Dockerfiles:

### Base Images
- Use specific version tags (e.g. `debian:bookworm-slim`), never `latest` in production.
- Prefer minimal base images (`-slim`, `-alpine`, `distroless`) to reduce attack surface and image size.
- Use official images from Docker Hub or verified publishers when available.

### Layer Optimisation
- Order instructions from least to most frequently changing to maximise layer cache hits.
- Combine related `RUN` commands with `&&` to reduce layer count.
- Use `--no-install-recommends` with `apt-get install` and clean up caches in the same layer:
  ```dockerfile
  RUN apt-get update && \
      apt-get install -y --no-install-recommends <packages> && \
      rm -rf /var/lib/apt/lists/*
  ```

### Multi-Stage Builds
- Use multi-stage builds to separate build-time dependencies from the runtime image.
- Copy only the necessary artefacts from builder stages.
- Name stages descriptively (e.g. `FROM ... AS builder`, `FROM ... AS runtime`).

### Security
- Run containers as a non-root user. Add a dedicated user with `RUN useradd` or `adduser` and switch with `USER`.
- Do not store secrets, passwords, or API keys in the image. Use build secrets (`--mount=type=secret`) or runtime environment injection.
- Minimise installed packages to reduce vulnerability surface.
- Use `COPY` instead of `ADD` unless tar extraction or URL fetching is specifically needed.
- Set `HEALTHCHECK` instructions for production images.

### General
- Always set a `WORKDIR` before `COPY`/`RUN` commands.
- Use `.dockerignore` to exclude unnecessary files from the build context.
- Prefer `ENTRYPOINT` with `CMD` for flexible, overridable startup commands.
- Pin package versions where reproducibility is important.
- Add metadata with `LABEL` (maintainer, version, description).

## Docker Compose Best Practices

Follow these practices when writing or reviewing `docker-compose.yml` (Compose v2):

### Service Configuration
- Use explicit `image:` tags or `build:` contexts — not both unless intentional.
- Define `depends_on` with `condition: service_healthy` where health checks are available.
- Set `restart: unless-stopped` or `restart: on-failure` for production services.
- Use named volumes for persistent data; avoid bind mounts in production where possible.

### Networking
- Define explicit networks rather than relying on the default bridge.
- Expose only necessary ports. Use `expose:` for inter-service communication and `ports:` only for host access.
- Use service names as hostnames for inter-container communication.

### Environment and Secrets
- Use `env_file:` for environment variables rather than inline `environment:` for sensitive values.
- Use Docker secrets or external secret managers for credentials.
- Never commit `.env` files containing real credentials to version control.

### Resource Management
- Set memory and CPU limits with `deploy.resources.limits` to prevent runaway containers.
- Configure logging drivers and log rotation to avoid filling disk.

### Development vs Production
- Use `docker-compose.override.yml` for development-specific overrides (bind mounts, debug ports).
- Keep the base `docker-compose.yml` production-ready.

## Troubleshooting Workflows

### Container Won't Start
1. Check the container logs: `docker logs <container>` or `docker compose logs <service>`.
2. Inspect the exit code: `docker inspect <container> --format='{{.State.ExitCode}}'`.
3. Verify the entrypoint/command is correct and the binary exists in the image.
4. Check for missing environment variables or configuration files.
5. Try running the container interactively: `docker run -it --entrypoint /bin/sh <image>`.

### Build Failures
1. Read the error message carefully — it usually points to the failing layer.
2. Check if the base image exists and is accessible.
3. Verify package names are correct for the base image's OS.
4. Ensure `COPY` source paths exist relative to the build context.
5. Use `docker build --no-cache` to rule out stale cache issues.

### Networking Issues
1. Verify containers are on the same Docker network: `docker network inspect <network>`.
2. Confirm service discovery is working using service names (not `localhost`).
3. Check that the application inside the container is binding to `0.0.0.0`, not `127.0.0.1`.
4. Inspect port mappings: `docker port <container>`.
5. Test connectivity from within a container: `docker exec <container> curl <target>`.

### Volume and Permission Issues
1. Check volume mounts: `docker inspect <container> --format='{{json .Mounts}}'`.
2. Verify file ownership inside the container matches the running user's UID/GID.
3. On Linux, host-mounted volumes inherit host permissions — ensure the container user has access.
4. Use `docker volume inspect <volume>` to check mount points.

### Image Size Issues
1. Use `docker history <image>` to identify large layers.
2. Use multi-stage builds to discard build tooling.
3. Remove package manager caches in the same `RUN` layer as installs.
4. Use `.dockerignore` to prevent copying unnecessary files into the build context.
5. Consider `dive` or `docker scout` for detailed image analysis.

## Key Docker Commands Reference

| Task | Command |
|------|---------|
| Build image | `docker build -t <name>:<tag> .` |
| Run container | `docker run -d --name <name> <image>` |
| View logs | `docker logs -f <container>` |
| Execute in container | `docker exec -it <container> /bin/bash` |
| List containers | `docker ps -a` |
| Stop/remove container | `docker stop <c> && docker rm <c>` |
| List images | `docker images` |
| Remove unused resources | `docker system prune -a` |
| Compose up | `docker compose up -d` |
| Compose down | `docker compose down` |
| Compose logs | `docker compose logs -f <service>` |
| Inspect container | `docker inspect <container>` |
| Network list | `docker network ls` |
| Volume list | `docker volume ls` |

## References

- Docker official documentation: https://docs.docker.com/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Docker Compose reference: https://docs.docker.com/compose/compose-file/
- Docker security best practices: https://docs.docker.com/build/building/best-practices/
- Docker Hub official images: https://hub.docker.com/search?q=&type=image&image_filter=official
