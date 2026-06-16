# Ubuntu → MacBook M5 Air migration kit

This folder contains everything needed to recreate your Ubuntu coding setup on the Mac.

## What's inside

| File | What it is |
|---|---|
| `setup-mac.sh` | One script that installs everything via Homebrew |
| `zshrc` | Your `~/.zshrc` (Oh My Zsh + Powerlevel10k + aliases) |
| `p10k.zsh` | Your Powerlevel10k prompt config |
| `gitconfig` | Your git name/email |
| `tmux.conf` | Your tmux config |
| `kitty.conf` | Your kitty terminal config |
| `vscode-extensions.txt` | Extension list — backup only; Settings Sync restores them after you log into VS Code |
| `transfer-dev.sh` | Copies `~/dev` (code + `.env` files) from Ubuntu to the Mac over WiFi |

## How to use it

1. **Copy this folder to the Mac.** Easiest options:
   - USB drive, or
   - push it to a private GitHub repo: `cd ~/macbook-setup && git init && git add . && git commit -m "setup" ` then push and clone on the Mac, or
   - if both machines are on the same WiFi: `scp -r ~/macbook-setup yourname@<mac-ip>:~/`
2. On the Mac, open Terminal and run:
   ```sh
   cd ~/macbook-setup && bash setup-mac.sh
   ```
3. If it stops after installing Xcode Command Line Tools (first run only), just run it again.
4. Follow the 6 manual steps printed at the end.

## Ubuntu → Mac translation (what changed)

| On Ubuntu | On Mac |
|---|---|
| `apt` / `snap` | Homebrew (`brew install`, `brew install --cask` for apps) |
| `docker.io` package | Docker Desktop app |
| `xclip` | built-in `pbcopy` / `pbpaste` |
| NVIDIA drivers, ibus, GNOME themes | not needed on macOS |
| iriun webcam | install from https://iriun.com (Mac version exists) |

Your `android*` aliases in `.zshrc` point to Waydroid, which doesn't exist on Mac —
they'll just error if you use them. If you need an Android emulator later,
install Android Studio: `brew install --cask android-studio`.

## Don't forget your data

These are NOT in this kit — copy them separately:

- **`~/dev` projects + `.env` secrets** — run `bash transfer-dev.sh hulesh@<mac-ip>` from Ubuntu.
  It copies code and gitignored `.env` files (GitHub does NOT have those), skipping
  node_modules/venvs (Linux binaries — reinstall with `npm install` / `pip install` on the Mac).
- **eVidyaloka Docker stack + MySQL DB** — the `evidyaloka/` folder has the Docker setup
  (Django 4.2 / Python 3.12 / MySQL 8.0 / Redis). After `move-dev.sh`, run `bash move-evidyaloka.sh`
  on the Mac: it copies the Docker files into the project and pulls the ~538 MB MySQL dump (too big
  for git), then `cd` into the project and run `./mac-setup.sh`. Details: `evidyaloka/DOCKER-SETUP.md`.
- **SSH keys** (`~/.ssh`) — copy the folder, then `chmod 600 ~/.ssh/id_*`
- **`~/.claude`** memory/settings (or just log in fresh)
- **WireGuard config** — re-add your tunnel in the WireGuard Mac app (App Store)

## Mac tips for an Ubuntu person

- `Cmd` replaces `Ctrl` for app shortcuts (copy = `Cmd+C`, even in kitty/terminal)
- Homebrew puts everything in `/opt/homebrew` (Apple Silicon)
- `brew services start mysql` ≈ `systemctl start mysql`
- macOS ships zsh as the default shell already — no `chsh` needed
