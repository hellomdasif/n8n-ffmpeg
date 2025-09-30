# Stage 1: downloader — grab static ffmpeg build
FROM debian:stable-slim AS downloader
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl xz-utils gnupg \
 && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    cd /tmp; \
    curl -sSL -o ffmpeg-static.tar.xz "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"; \
    tar -xJf ffmpeg-static.tar.xz; \
    FDIR="$(ls -d ffmpeg-*-amd64-static | head -n1)"; \
    cp "$FDIR"/ffmpeg /tmp/ffmpeg; \
    cp "$FDIR"/ffprobe /tmp/ffprobe; \
    chmod a+rx /tmp/ffmpeg /tmp/ffprobe

# (optional) download standalone linux yt-dlp binary (multiarch or amd64)
# If you want yt-dlp standalone binary (no Python), uncomment:
# RUN curl -sSL -o /tmp/yt-dlp "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux" && chmod a+rx /tmp/yt-dlp

# Stage 2: final image (Alpine-based n8n:next)
FROM docker.n8n.io/n8nio/n8n:next AS final

USER root

# Install system deps, python + pip, ImageMagick + pango + emoji font
RUN apk update \
 && apk add --no-cache \
      python3 py3-pip \
      imagemagick \
      cairo pango gdk-pixbuf \
      font-noto font-noto-emoji \
 && python3 -m pip install --no-cache-dir --break-system-packages -U yt-dlp \
 && rm -rf /var/cache/apk/*

# Copy static ffmpeg/ffprobe (and optional yt-dlp) from downloader stage
COPY --from=downloader /tmp/ffmpeg /usr/local/bin/ffmpeg
COPY --from=downloader /tmp/ffprobe /usr/local/bin/ffprobe
#COPY --from=downloader /tmp/yt-dlp /usr/local/bin/yt-dlp    # optional

# Ensure binaries are executable
RUN chmod a+rx /usr/local/bin/ffmpeg /usr/local/bin/ffprobe

# Switch back to the original user from base image
USER node
