#!/bin/bash
# MacBook setup script — mirrors hulesh's Ubuntu dev environment.
# Run this ON THE MACBOOK from inside the macbook-setup folder:
#   cd ~/macbook-setup && bash setup-mac.sh
set -e

KIT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Step 1/8: Xcode Command Line Tools (gcc, make, git)"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install
  echo "A popup opened — finish that install, then re-run this script."
  exit 0
fi

echo "==> Step 2/8: Homebrew (Mac's apt)"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "==> Step 3/8: CLI tools"
brew install \
  bat eza fzf ripgrep htop zoxide tmux tmate neovim wget watchman \
  mysql openjdk@21 python@3.12 bun gh

# Java: make openjdk@21 visible to the system
sudo ln -sfn "$(brew --prefix openjdk@21)/libexec/openjdk.jdk" \
  /Library/Java/JavaVirtualMachines/openjdk-21.jdk 2>/dev/null || true

echo "==> Step 4/8: Desktop apps"
brew install --cask \
  kitty visual-studio-code google-chrome brave-browser firefox \
  postman slack vlc docker mysqlworkbench burp-suite \
  android-studio google-cloud-sdk
# Antigravity IDE (skip silently if the cask isn't available yet)
brew install --cask antigravity 2>/dev/null || echo "  (antigravity cask not found — install from antigravity.google manually)"

echo "==> Step 5/8: Fonts for Powerlevel10k"
brew install --cask font-meslo-lg-nerd-font

echo "==> Step 6/8: Oh My Zsh + Powerlevel10k + plugins"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ] || git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

echo "==> Step 7/8: Restore dotfiles (paths fixed for Mac)"
for pair in "zshrc:.zshrc" "p10k.zsh:.p10k.zsh" "gitconfig:.gitconfig" "tmux.conf:.tmux.conf"; do
  src="${pair%%:*}"; dst="${pair##*:}"
  if [ -f "$KIT_DIR/$src" ]; then
    sed "s|/home/hulesh|$HOME|g" "$KIT_DIR/$src" > "$HOME/$dst"
    echo "  restored ~/$dst"
  fi
done
mkdir -p "$HOME/.config/kitty"
[ -f "$KIT_DIR/kitty.conf" ] && cp "$KIT_DIR/kitty.conf" "$HOME/.config/kitty/kitty.conf"

echo "==> Step 8/8: Node (nvm), Bun globals, dev folder"
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"
nvm install 24
nvm alias default 24

npm install -g \
  @anthropic-ai/claude-code @google/gemini-cli @openai/codex \
  @playwright/cli agent-browser openclaw

mkdir -p "$HOME/dev"/{freelance,job-prep,learning,personal,sandbox,tools,work}

# VS Code extensions
if command -v code >/dev/null 2>&1 && [ -f "$KIT_DIR/vscode-extensions.txt" ]; then
  echo "==> Installing VS Code extensions (85 of them — takes a while)"
  while read -r ext; do
    code --install-extension "$ext" --force || true
  done < "$KIT_DIR/vscode-extensions.txt"
fi

echo ""
echo "✅ Done! Now do these by hand:"
echo "  1. Open a NEW terminal — Powerlevel10k prompt should appear (run 'p10k configure' if fonts look broken)"
echo "  2. Open Docker.app once to finish Docker Desktop setup"
echo "  3. Open Android Studio once — it downloads the Android SDK + emulator (replaces Waydroid)"
echo "  4. gcloud init   (log in to Google Cloud again)"
echo "  5. claude login / gemini / codex — log in to your AI CLIs again"
echo "  6. brew services start mysql   (then import your DB dump if you have one)"
