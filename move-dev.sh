#!/usr/bin/env bash
# move-dev.sh — pull all dev projects from the Linux box to this Mac
# Run this ON THE MACBOOK.
set -euo pipefail

# ---- config ----
LINUX_USER="hulesh"
LINUX_HOST="192.168.31.108"   # change if the Linux box IP changes
SRC="/home/hulesh/dev/"        # trailing slash matters
DEST="$HOME/dev/"
# ----------------

echo "==> Transferring $LINUX_USER@$LINUX_HOST:$SRC  ->  $DEST"
mkdir -p "$DEST"

rsync -avz --partial --progress \
  --exclude 'node_modules' \
  --exclude '.next' --exclude 'dist' --exclude 'build' --exclude 'out' \
  --exclude '.venv' --exclude 'venv' --exclude '__pycache__' \
  --exclude '.turbo' --exclude '.cache' \
  "$LINUX_USER@$LINUX_HOST:$SRC" "$DEST"

echo ""
echo "Transfer complete."
echo "  Your git history + uncommitted changes are intact."
echo ""
echo "To reinstall deps for a project, run 'npm install' (or pnpm/yarn)"
echo "inside that project folder. node_modules was skipped on purpose"
echo "since Apple Silicon needs its own native binaries."
