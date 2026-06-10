#!/usr/bin/env bash
# Extract a numbered JPG frame sequence from a video for scroll-scrubbing.
# Usage: extract-frames.sh <video> <out_dir> [frame_count]
# Example: extract-frames.sh hero.mp4 ./frames 150
set -euo pipefail

VIDEO="${1:?usage: extract-frames.sh <video> <out_dir> [frame_count]}"
OUT="${2:?usage: extract-frames.sh <video> <out_dir> [frame_count]}"
COUNT="${3:-150}"

# Locate ffmpeg (PATH, or the static binary this project may have downloaded).
FFMPEG="$(command -v ffmpeg || true)"
[ -z "$FFMPEG" ] && [ -x /tmp/ffmpeg-bin/ffmpeg ] && FFMPEG=/tmp/ffmpeg-bin/ffmpeg
[ -z "$FFMPEG" ] && { echo "ffmpeg not found. Install it or set FFMPEG."; exit 1; }

mkdir -p "$OUT"
rm -f "$OUT"/frame_*.jpg

# Video duration (seconds) → fps that yields ~COUNT evenly spaced frames.
# Capture probe output first (avoids SIGPIPE tripping pipefail).
PROBE="$("$FFMPEG" -i "$VIDEO" 2>&1 || true)"
DUR="$(printf '%s\n' "$PROBE" | awk '/Duration/{split($2,a,":");print a[1]*3600+a[2]*60+a[3];exit}')"
FPS="$(awk -v c="$COUNT" -v d="$DUR" 'BEGIN{ if(d<=0)d=1; printf "%.4f", c/d }')"

echo "Duration ${DUR}s → ${FPS} fps for ~${COUNT} frames"
"$FFMPEG" -y -i "$VIDEO" -vf "fps=${FPS}" -q:v 3 "$OUT/frame_%04d.jpg" -hide_banner -loglevel error

ACTUAL="$(ls "$OUT"/frame_*.jpg | wc -l | tr -d ' ')"
echo "Wrote ${ACTUAL} frames to ${OUT}"
echo "Set FRAME_COUNT = ${ACTUAL} in your scroll-cinematic config."
