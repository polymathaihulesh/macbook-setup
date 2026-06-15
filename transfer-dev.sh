#!/bin/bash
# Transfer ~/dev (code + .env files) from Ubuntu to the MacBook over WiFi.
# Skips node_modules / venvs / build folders — those are Linux x86 binaries
# that DON'T work on Apple Silicon and must be reinstalled on the Mac anyway.
#
# Run this FROM UBUNTU:
#   bash transfer-dev.sh hulesh@<mac-ip>
#
# First turn on the Mac: System Settings > General > Sharing > Remote Login.
set -e

DEST="$1"
SRC="$HOME/dev/"

if [ -z "$DEST" ]; then
  echo "Usage: bash transfer-dev.sh hulesh@<mac-ip>"
  echo "  e.g. bash transfer-dev.sh hulesh@192.168.1.42"
  echo "  (find the address on the Mac under Sharing > Remote Login)"
  exit 1
fi

EXCLUDES=(
  --exclude node_modules
  --exclude .venv
  --exclude venv
  --exclude env
  --exclude __pycache__
  --exclude .next
  --exclude dist
  --exclude build
  --exclude .gradle
  --exclude target
  --exclude .turbo
  --exclude .cache
  --exclude .expo
)

# Count what should land on the other side (real secrets, not .example templates)
ENV_COUNT=$(find "$HOME/dev" -name ".env" -o -name ".env.local" -o -name ".env.development" -o -name ".env.production" 2>/dev/null | grep -vE 'node_modules|\.venv|/venv/' | wc -l | tr -d ' ')

echo "==> Source:      $SRC"
echo "==> Destination: $DEST:~/dev/"
echo "==> .env secrets to carry over: $ENV_COUNT"
echo ""

# Dry run first so you see what's about to move, then confirm.
echo "==> DRY RUN (nothing copied yet)..."
rsync -azn --partial "${EXCLUDES[@]}" --stats "$SRC" "$DEST:~/dev/" | tail -15
echo ""
read -r -p "Proceed with the real transfer? [y/N] " ok
[ "$ok" = "y" ] || [ "$ok" = "Y" ] || { echo "Aborted."; exit 0; }

echo ""
echo "==> Transferring (resumable — rerun this script if it drops)..."
rsync -avz --partial --info=progress2 "${EXCLUDES[@]}" "$SRC" "$DEST:~/dev/"

echo ""
echo "✅ Transfer done."
echo ""
echo "Now VERIFY on the Mac — open a terminal there and run:"
echo "  find ~/dev -name '.env' -o -name '.env.local' | grep -v node_modules | wc -l"
echo "  → should print around $ENV_COUNT"
echo ""
echo "Then in each project, rebuild the skipped folders:"
echo "  npm install      (or: bun install)"
echo "  python3 -m venv .venv && pip install -r requirements.txt"
