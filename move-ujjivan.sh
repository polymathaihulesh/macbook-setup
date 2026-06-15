#!/usr/bin/env bash
# move-ujjivan.sh — pull the ~/ujjivan_Repo SonarQube scan workspace to this Mac.
# Run this ON THE MACBOOK. Lands at ~/ujjivan_Repo so rescan.sh paths match.
set -euo pipefail

LINUX_USER="hulesh"
LINUX_HOST="192.168.31.108"
SRC="/home/hulesh/ujjivan_Repo/"   # trailing slash matters
DEST="$HOME/ujjivan_Repo/"

echo "==> Transferring $LINUX_USER@$LINUX_HOST:$SRC  ->  $DEST"
mkdir -p "$DEST"

rsync -avz --partial --progress \
  --exclude 'node_modules' \
  --exclude '.next' --exclude 'dist' --exclude 'build' --exclude 'out' \
  --exclude '.venv' --exclude 'venv' --exclude '__pycache__' \
  --exclude 'coverage' --exclude '.turbo' --exclude '.cache' \
  "$LINUX_USER@$LINUX_HOST:$SRC" "$DEST"

echo ""
echo "Done. Git history + uncommitted changes are intact."
echo ""
echo "Before re-scanning on the Mac:"
echo "  1. Start SonarQube (see sonar-restore.sh) and confirm http://localhost:9000"
echo "  2. Reinstall deps per project (npm/bun install, python venv + pip)"
echo "  3. Run: cd ~/ujjivan_Repo && ./rescan.sh"
