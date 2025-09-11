# Stage 1: downloader (has package manager) — grabs static ffmpeg build and yt-dlp (linux standalone)
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

# download the standalone linux yt-dlp binary (does NOT require python at runtime)
RUN curl -sSL -o /tmp/yt-dlp "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux" && \
    chmod a+rx /tmp/yt-dlp

# Stage 2: final image based on official n8n image
FROM docker.n8n.io/n8nio/n8n:latest

USER root

# copy the static binaries into the final image
COPY --from=downloader /tmp/ffmpeg /usr/local/bin/ffmpeg
COPY --from=downloader /tmp/ffprobe /usr/local/bin/ffprobe
COPY --from=downloader /tmp/yt-dlp /usr/local/bin/yt-dlp

# permissions and ownership for the n8n user
RUN chmod a+rx /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /usr/local/bin/yt-dlp \
 && chown node:node /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /usr/local/bin/yt-dlp

USER node
