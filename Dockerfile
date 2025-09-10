cat > Dockerfile <<'EOF'
# Stage 1: downloader (has package manager) — grabs static ffmpeg build
FROM debian:stable-slim AS downloader

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl xz-utils \
 && rm -rf /var/lib/apt/lists/*

# download static amd64 ffmpeg release and extract
RUN set -eux; \
    cd /tmp; \
    curl -sSL -o ffmpeg-static.tar.xz "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"; \
    tar -xJf ffmpeg-static.tar.xz; \
    FDIR="$(ls -d ffmpeg-*-amd64-static | head -n1)"; \
    cp "$FDIR"/ffmpeg /tmp/ffmpeg; \
    cp "$FDIR"/ffprobe /tmp/ffprobe; \
    chmod +x /tmp/ffmpeg /tmp/ffprobe

# Stage 2: final image based on official n8n image
FROM docker.n8n.io/n8nio/n8n:latest

USER root

# copy the static binaries into the final image
COPY --from=downloader /tmp/ffmpeg /usr/local/bin/ffmpeg
COPY --from=downloader /tmp/ffprobe /usr/local/bin/ffprobe

RUN chmod +x /usr/local/bin/ffmpeg /usr/local/bin/ffprobe \
 && chown node:node /usr/local/bin/ffmpeg /usr/local/bin/ffprobe

USER node
EOF
