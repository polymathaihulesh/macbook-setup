#!/usr/bin/env bash
# install-deps.sh — walk every project under ~/dev and install JS deps
# using the right package manager detected from each project's lockfile.
# Run this ON THE MACBOOK, after move-dev.sh finishes.
set -uo pipefail

ROOT="${1:-$HOME/dev}"
echo "==> Scanning $ROOT for projects with a package.json ..."

# find package.json files, skip anything already inside a node_modules
find "$ROOT" -name package.json -not -path '*/node_modules/*' -print0 |
while IFS= read -r -d '' pkg; do
  dir="$(dirname "$pkg")"
  echo ""
  echo "---- $dir ----"
  (
    cd "$dir"
    if   [ -f pnpm-lock.yaml ]; then echo "pnpm install";  pnpm install
    elif [ -f yarn.lock ];      then echo "yarn install";  yarn install
    elif [ -f bun.lockb ];      then echo "bun install";   bun install
    else                              echo "npm install";   npm install
    fi
  ) || echo "  !! install failed in $dir (skipping, continuing)"
done

echo ""
echo "Done. Any failures above are listed with '!!' — handle those manually."
