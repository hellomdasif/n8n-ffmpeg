# Stage 1: downloader — grab static ffmpeg build
FROM debian:stable-slim AS downloader

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl xz-utils gnupg \
 && rm -rf /var/lib/apt/lists/*

# download static amd64 ffmpeg release and extract
RUN set -eux; \
    cd /tmp; \
    curl -sSL -o ffmpeg-static.tar.xz "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"; \
    tar -xJf ffmpeg-static.tar.xz; \
    FDIR="$(ls -d ffmpeg-*-amd64-static | head -n1)"; \
    cp "$FDIR"/ffmpeg /tmp/ffmpeg; \
    cp "$FDIR"/ffprobe /tmp/ffprobe; \
    chmod a+rx /tmp/ffmpeg /tmp/ffprobe

# -------------------------------
# Stage 2: final image (Debian-based / apt available)
# -------------------------------
FROM node:20-bullseye-slim AS final

ENV DEBIAN_FRONTEND=noninteractive
ENV N8N_USER=node
ENV N8N_HOME=/home/node

USER root

# Install system deps, python + pip, and install n8n and yt-dlp
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    python3 python3-pip ca-certificates curl gnupg \
 && python3 -m pip install --no-cache-dir -U yt-dlp \
 && npm install -g n8n@latest \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Copy static ffmpeg/ffprobe from downloader stage
COPY --from=downloader /tmp/ffmpeg /usr/local/bin/ffmpeg
COPY --from=downloader /tmp/ffprobe /usr/local/bin/ffprobe

# Ensure binaries are executable and owned by node user
RUN chmod a+rx /usr/local/bin/ffmpeg /usr/local/bin/ffprobe \
 && chown -R ${N8N_USER}:${N8N_USER} /usr/local/bin/ffmpeg /usr/local/bin/ffprobe

# create n8n user home (node image usually has it)
RUN mkdir -p ${N8N_HOME} && chown -R ${N8N_USER}:${N8N_USER} ${N8N_HOME}

# Switch to non-root user
USER ${N8N_USER}

# Expose default n8n port
EXPOSE 5678

# Default command (same as running `n8n`), can be overridden by Coolify environment/entrypoint config
# Keep it simple — Coolify usually adds envs and overrides as needed
CMD ["n8n", "start"]
