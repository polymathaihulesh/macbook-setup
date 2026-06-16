#!/bin/bash
# Minimal Mac setup — essentials only.
# CLI: ripgrep, fzf, bun.  Apps: VS Code, Chrome, Slack, Docker.
# Node via nvm + Claude Code CLI.  Keeps your ~/.gitconfig (dual-account) untouched.
# Run: cd ~/macbook-setup && bash setup-mac-min.sh
set -e

echo "==> Step 1/5: Homebrew (Mac's apt)"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

echo "==> Step 2/5: CLI tools"
brew install ripgrep fzf bun

echo "==> Step 3/5: Desktop apps"
brew install --cask \
  visual-studio-code google-chrome slack docker

echo "==> Step 4/5: Make brew + nvm load in a plain terminal (~/.zprofile)"
touch "$HOME/.zprofile"
grep -q 'brew shellenv' "$HOME/.zprofile" || \
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"

echo "==> Step 5/5: Node (nvm), Claude Code, dev folders"
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"
nvm install 24
nvm alias default 24

grep -q 'NVM_DIR' "$HOME/.zprofile" || cat >> "$HOME/.zprofile" <<'EOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
EOF

npm install -g @anthropic-ai/claude-code

mkdir -p "$HOME/dev"/{freelance,job-prep,learning,personal,sandbox,tools,work}

echo ""
echo "✅ Done (essentials only). Now do these by hand:"
echo "  1. Open Docker.app once to finish Docker Desktop setup"
echo "  2. Open VS Code, log in and enable Settings Sync"
echo "  3. claude — log in to Claude Code"
