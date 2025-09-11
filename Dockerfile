# Stage 1: downloader (has package manager) — grabs static ffmpeg build
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

# ----------------------
# Stage 2: final image based on official n8n image
# ----------------------
FROM docker.n8n.io/n8nio/n8n:latest

USER root

# copy the static binaries into the final image
COPY --from=downloader /tmp/ffmpeg /usr/local/bin/ffmpeg
COPY --from=downloader /tmp/ffprobe /usr/local/bin/ffprobe

# Install python & pip, install yt-dlp via pip (build-time).
# Clean apt lists to keep final image small. Make sure n8n (node) user can execute binaries.
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 python3-pip ca-certificates curl \
 && python3 -m pip install --no-cache-dir -U yt-dlp \
 && chmod a+rx /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /usr/local/bin/yt-dlp \
 && chown node:node /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /usr/local/bin/yt-dlp \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Switch back to non-root user used by n8n
USER node
