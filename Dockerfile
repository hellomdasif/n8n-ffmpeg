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

# Stage 2: final image (Debian-based / apt available)
FROM node:20-bullseye-slim AS final
ENV DEBIAN_FRONTEND=noninteractive
ENV N8N_USER=node
ENV N8N_HOME=/home/node

USER root

# Install system deps, python + pip, ImageMagick + pango + emoji font, and n8n
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 python3-pip ca-certificates curl gnupg \
      imagemagick \
      libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 \
      fonts-noto-color-emoji fonts-noto-core fonts-noto-ui-core \
 && python3 -m pip install --no-cache-dir -U yt-dlp \
 && npm install -g n8n@next \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Copy static ffmpeg/ffprobe (and optional yt-dlp) from downloader stage
COPY --from=downloader /tmp/ffmpeg /usr/local/bin/ffmpeg
COPY --from=downloader /tmp/ffprobe /usr/local/bin/ffprobe
#COPY --from=downloader /tmp/yt-dlp /usr/local/bin/yt-dlp    # optional

# Ensure binaries are executable (no chown to avoid user lookup issues)
RUN chmod a+rx /usr/local/bin/ffmpeg /usr/local/bin/ffprobe \
 && rm -rf /tmp/ffmpeg-static* /tmp/ffmpeg-static.tar.xz || true

# Optional simple healthcheck to ensure ImageMagick is present at runtime
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1 || exit 1

# Make sure n8n home exists and is writable
RUN mkdir -p ${N8N_HOME} && chown -R ${N8N_USER}:${N8N_USER} ${N8N_HOME} || true

# Switch to non-root user
USER ${N8N_USER}

EXPOSE 5678

CMD ["n8n", "start"]