#!/usr/bin/env bash
# Single-click run of the web build on Linux/macOS.
set -e

cd "$(dirname "$0")"

WEB_DIR="build/web"
PORT="${PORT:-8080}"

if [ ! -f "$WEB_DIR/index.html" ]; then
  echo "Web build missing. Run: flutter build web --release"
  exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
else
  echo "Python not found. Install it or serve $WEB_DIR manually."
  exit 1
fi

"$PY" -m http.server "$PORT" --directory "$WEB_DIR" >/dev/null 2>&1 &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null' EXIT

sleep 1
URL="http://localhost:$PORT"
echo "Inventory app running at $URL  (Ctrl+C to stop)"

case "$(uname -s)" in
  Darwin) open "$URL" ;;
  Linux) xdg-open "$URL" >/dev/null 2>&1 & ;;
esac

wait "$SERVER_PID"