#!/usr/bin/env bash
# Downscale + compress a frame folder so the whole sequence loads fast.
# Usage: compress-frames.sh <dir> [max_width] [quality]
# Defaults: max_width=1280, quality=80 (JPG). Uses ffmpeg if present, else sips (macOS).
set -euo pipefail

DIR="${1:?usage: compress-frames.sh <dir> [max_width] [quality]}"
MAXW="${2:-1280}"
Q="${3:-80}"

FFMPEG="$(command -v ffmpeg || true)"
[ -z "$FFMPEG" ] && [ -x /tmp/ffmpeg-bin/ffmpeg ] && FFMPEG=/tmp/ffmpeg-bin/ffmpeg

shopt -s nullglob
files=("$DIR"/frame_*.jpg)
[ ${#files[@]} -eq 0 ] && { echo "No frame_*.jpg in $DIR"; exit 1; }

if [ -n "$FFMPEG" ]; then
  qv=$(( (100 - Q) * 31 / 100 )); [ "$qv" -lt 2 ] && qv=2   # map quality→ffmpeg -q:v
  for f in "${files[@]}"; do
    "$FFMPEG" -y -i "$f" -vf "scale='min($MAXW,iw)':-2" -q:v "$qv" "$f.tmp.jpg" -hide_banner -loglevel error
    mv "$f.tmp.jpg" "$f"
  done
else
  # macOS fallback
  for f in "${files[@]}"; do
    sips --resampleWidth "$MAXW" -s formatOptions "$Q" "$f" >/dev/null 2>&1 || true
  done
fi

TOTAL=$(du -sh "$DIR" | cut -f1)
echo "Compressed ${#files[@]} frames in $DIR → total $TOTAL (max ${MAXW}px, q${Q})"
