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

# Stage 2: final image (Debian-based / apt available)
FROM node:20-bullseye-slim AS final
ENV DEBIAN_FRONTEND=noninteractive
ENV N8N_USER=node
ENV N8N_HOME=/home/node
ENV CACHE_BUST=2025-10-05-v8

USER root

# Install system deps, python + pip, ImageMagick + pango + emoji font, Pillow dependencies, and n8n
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 python3-pip ca-certificates curl wget gnupg procps \
      imagemagick \
      libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 \
      libjpeg-dev zlib1g-dev libfreetype6-dev \
      fonts-noto-color-emoji fonts-noto-core fonts-noto-ui-core \
 && python3 -m pip install --no-cache-dir -U yt-dlp gallery-dl Pillow rembg onnxruntime \
 && npm install -g n8n \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Copy static ffmpeg/ffprobe from downloader stage
COPY --from=downloader /tmp/ffmpeg /usr/local/bin/ffmpeg
COPY --from=downloader /tmp/ffprobe /usr/local/bin/ffprobe

# Copy startup script and healthcheck
COPY start.sh /usr/local/bin/start.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

# Ensure binaries are executable
RUN chmod a+rx /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /usr/local/bin/start.sh /usr/local/bin/healthcheck.sh \
 && rm -rf /tmp/ffmpeg-static* /tmp/ffmpeg-static.tar.xz || true

# Make sure n8n home exists and is writable
RUN mkdir -p ${N8N_HOME} && chown -R ${N8N_USER}:${N8N_USER} ${N8N_HOME} || true

# Fix Ollama permissions for node user
RUN mkdir -p /usr/share/ollama/.ollama && chown -R ${N8N_USER}:${N8N_USER} /usr/share/ollama/.ollama

# Switch to non-root user
USER ${N8N_USER}

# Define persistent volumes
VOLUME ["/home/node/.n8n", "/usr/share/ollama/.ollama"]

EXPOSE 5678 11434

# Healthcheck that always succeeds (Coolify needs this)
HEALTHCHECK --interval=5s --timeout=3s --start-period=30s --retries=3 \
  CMD /usr/local/bin/healthcheck.sh

CMD ["/usr/local/bin/start.sh"]