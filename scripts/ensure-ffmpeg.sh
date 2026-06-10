#!/usr/bin/env bash
# Ensure ffmpeg is available WITHOUT requiring Homebrew or a manual install.
# Order: system ffmpeg → cached static binary → download a static build.
# Prints the usable ffmpeg path on success (also usable as $FFMPEG by the other scripts).
set -euo pipefail

# 1) already on PATH?
if command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg: $(command -v ffmpeg)"; exit 0
fi

# 2) already downloaded this session?
if [ -x /tmp/ffmpeg-bin/ffmpeg ]; then
  echo "ffmpeg: /tmp/ffmpeg-bin/ffmpeg"; exit 0
fi

mkdir -p /tmp/ffmpeg-bin
OS="$(uname -s)"

if [ "$OS" = "Darwin" ]; then
  # macOS static build (no Homebrew needed)
  echo "Downloading static ffmpeg for macOS..."
  curl -fsSL -o /tmp/ffmpeg-bin/ffmpeg.zip "https://evermeet.cx/ffmpeg/getrelease/zip"
  unzip -o /tmp/ffmpeg-bin/ffmpeg.zip -d /tmp/ffmpeg-bin >/dev/null
  chmod +x /tmp/ffmpeg-bin/ffmpeg
elif [ "$OS" = "Linux" ]; then
  echo "Downloading static ffmpeg for Linux..."
  curl -fsSL -o /tmp/ffmpeg-bin/ffmpeg.tar.xz "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
  tar -xf /tmp/ffmpeg-bin/ffmpeg.tar.xz -C /tmp/ffmpeg-bin --strip-components=1 --wildcards "*/ffmpeg"
  chmod +x /tmp/ffmpeg-bin/ffmpeg
else
  echo "Unsupported OS ($OS). Install ffmpeg manually." >&2; exit 1
fi

if [ -x /tmp/ffmpeg-bin/ffmpeg ]; then
  /tmp/ffmpeg-bin/ffmpeg -version | head -1
  echo "ffmpeg: /tmp/ffmpeg-bin/ffmpeg"
else
  echo "ffmpeg install failed." >&2; exit 1
fi
