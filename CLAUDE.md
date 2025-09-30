# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a custom Docker image that extends the official n8n workflow automation platform with multimedia processing capabilities. The image is built on Debian (node:20-bullseye-slim) and includes:

- **n8n** (latest): Workflow automation platform
- **ffmpeg & ffprobe**: Static binaries from johnvansickle.com for video/audio processing
- **yt-dlp**: Python-based tool for downloading media from various platforms
- **ImageMagick**: Image processing with Pango rendering support and Noto emoji fonts

## Docker Commands

### Build the image
```bash
docker build -t n8n-ffmpeg .
```

### Run the container
```bash
docker run -d -p 5678:5678 n8n-ffmpeg
```

### Run with volume mounts (for persistent data)
```bash
docker run -d -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8n-ffmpeg
```

## Architecture

### Multi-stage Build
The Dockerfile uses a two-stage build process:

1. **Stage 1 (downloader)**: Downloads and extracts the static ffmpeg build
2. **Stage 2 (final)**: Based on Node.js 20 on Debian, installs system dependencies, Python packages, and copies binaries from stage 1

### Key Design Decisions

- **Static ffmpeg binaries**: Used instead of apt packages to ensure consistency and include all codecs
- **Python + pip-installed yt-dlp**: Preferred over standalone binary for better compatibility and updates
- **Debian base**: Chosen over Alpine to support apt and provide better compatibility with n8n and multimedia tools
- **Non-root user**: Runs as `node` user for security
- **Healthcheck**: Validates ImageMagick availability at runtime

### Binary Locations
- ffmpeg: `/usr/local/bin/ffmpeg`
- ffprobe: `/usr/local/bin/ffprobe`
- yt-dlp: Installed via pip, available in PATH
- ImageMagick: Available as `magick` or `convert` commands

## Modifying the Image

### Adding yt-dlp standalone binary
Uncomment lines 20 and 45 in [Dockerfile](Dockerfile) to use the standalone Linux binary instead of pip-installed version.

### Changing n8n version
Edit line 38 in [Dockerfile](Dockerfile:38): replace `n8n@latest` with specific version like `n8n@1.x.x`

### Adding additional tools
Add to the `apt-get install` command on lines 31-40, then clean up in the same RUN layer to keep image size small.