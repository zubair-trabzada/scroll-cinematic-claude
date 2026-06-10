#!/bin/bash
# Double-click to launch the demo site locally.
# Keep this window open while recording. Press Ctrl+C (or close it) to stop.
# EDIT the PORT and NAME for each project.

cd "$(dirname "$0")" || exit 1
PORT=8090
NAME="Demo"

lsof -nP -iTCP:$PORT -sTCP:LISTEN -t 2>/dev/null | xargs kill -9 2>/dev/null
URL="http://localhost:$PORT"
echo ""
echo "  $NAME — local server"
echo "  Open in your browser:  $URL"
echo "  Keep this window open while recording. Ctrl+C to stop."
echo ""
( sleep 1 && open "$URL" ) &
python3 -m http.server $PORT
