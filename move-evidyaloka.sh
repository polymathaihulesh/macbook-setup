#!/usr/bin/env bash
# move-evidyaloka.sh — set up the eVidyaloka Docker stack on this Mac.
# Run this ON THE MACBOOK, AFTER move-dev.sh has brought the project code over.
#
# What it does:
#   1) copies the Docker files from this repo into the eVidyaloka project root,
#   2) pulls the MySQL dump (~538 MB) from the Linux box into the project's
#      db_dumps/ (the dump is NOT in git — too big — so it comes over rsync),
#   3) verifies the dump, then tells you to run ./mac-setup.sh.
set -euo pipefail

LINUX_USER="hulesh"
LINUX_HOST="192.168.31.108"                                   # change if the Linux box IP changes
DUMP_SRC="/home/hulesh/macbook-setup/evidyaloka/db_dumps/"     # dump lives here on Linux (git-ignored)
PROJECT="$HOME/dev/work/polymath/ev/eVidyaloka-jupiter"        # where move-dev.sh lands the code
SETUP="$HOME/macbook-setup/evidyaloka"                         # this repo, cloned on the Mac

[ -d "$PROJECT" ] || { echo "✘ Project not found at $PROJECT — run move-dev.sh first."; exit 1; }
[ -d "$SETUP" ]   || { echo "✘ $SETUP not found — clone/pull the macbook-setup repo first."; exit 1; }

echo "==> 1/3 Copying Docker files into the project root"
cp "$SETUP"/Dockerfile "$SETUP"/docker-compose.yml "$SETUP"/config_docker.py \
   "$SETUP"/.dockerignore "$SETUP"/mac-setup.sh  "$PROJECT/"
mkdir -p "$PROJECT/db_dumps"
echo "  done"

echo "==> 2/3 Pulling DB dump (~538 MB) from $LINUX_USER@$LINUX_HOST (resumable)"
# Use a modern rsync if one is installed (e.g. Homebrew's), otherwise fall back
# to flags the stock macOS rsync (2.6.9) understands.
if rsync --version 2>/dev/null | grep -q 'version 3'; then
  rsync -ah --partial --info=progress2 --skip-compress=gz \
    "$LINUX_USER@$LINUX_HOST:$DUMP_SRC" "$PROJECT/db_dumps/"
else
  rsync -a --partial --progress \
    "$LINUX_USER@$LINUX_HOST:$DUMP_SRC" "$PROJECT/db_dumps/"
fi

echo "==> 3/3 Verifying dump integrity"
if ( cd "$PROJECT/db_dumps" && shasum -a 256 -c evd_replica.sql.gz.sha256 ); then
  echo "  ✔ dump verified"
else
  echo "  ✘ checksum mismatch — re-run this script to resume the transfer"; exit 1
fi

echo ""
echo "✅ eVidyaloka is wired up. Start the stack:"
echo "     cd $PROJECT && ./mac-setup.sh"
echo "   (first 'up' imports the 4.7 GB DB — give it several minutes)"
