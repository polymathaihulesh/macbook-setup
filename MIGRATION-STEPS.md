# Ubuntu → MacBook M5 Air — full move checklist

Work top to bottom. Don't wipe the Ubuntu machine until the last section passes.

## Phase 0 — On Ubuntu, before you touch the Mac

- [ ] **Push all git repos** (backup safety net):
      in each of your 7 repos run `git status`, then `git add -A && git commit` and `git push`.
- [ ] **This kit is already on GitHub** at `polymathaihulesh/macbook-setup` (private). Good.
- [ ] Make sure both machines are on the **same WiFi** for the transfers.
- [ ] Know your Ubuntu has ~7.8 GB of real code to move (the rest is node_modules/venvs we skip).

## Phase 1 — First boot of the MacBook

- [ ] Go through macOS setup (Apple ID, WiFi, name your account `hulesh`).
- [ ] Open **Terminal** (Cmd+Space, type "Terminal"). It's plain zsh for now — that's expected.
- [ ] Turn on file sharing so Ubuntu can push to it:
      **System Settings → General → Sharing → Remote Login = ON**.
      Note the address it shows, e.g. `hulesh@192.168.1.42`.

## Phase 2 — Get the kit onto the Mac

Easiest is HTTPS clone (your SSH keys aren't on the Mac yet):

```sh
git clone https://github.com/polymathaihulesh/macbook-setup.git ~/macbook-setup
```

It will ask you to log in to GitHub in the browser — use your work account.

## Phase 3 — Copy your SSH keys (from Ubuntu)

Run on **Ubuntu** (uses the Remote Login you turned on):

```sh
scp -r ~/.ssh hulesh@<mac-ip>:~/
```

Then on the **Mac**, fix permissions:

```sh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_* ~/.ssh/config
chmod 644 ~/.ssh/*.pub
ssh -T git@github.com        # → "Hi huleshjangde!"
ssh -T git@work.github       # → "Hi polymathaihulesh!"
```

## Phase 4 — Install the environment (on the Mac)

```sh
cd ~/macbook-setup
bash setup-mac.sh
```

- [ ] First run installs Xcode Command Line Tools and **stops** — when that popup finishes,
      run `bash setup-mac.sh` **again**.
- [ ] Second run installs Homebrew, all CLI tools, apps, Oh My Zsh + Powerlevel10k, Node, etc.
      Takes 20–40 min. Enter your Mac password when asked.
- [ ] **Open a NEW terminal** — your Powerlevel10k prompt should appear.
      If icons look broken, set kitty's font to "MesloLGS NF" or run `p10k configure`.

## Phase 5 — Transfer your projects + .env files (from Ubuntu)

Run on **Ubuntu**:

```sh
cd ~/macbook-setup
bash transfer-dev.sh hulesh@<mac-ip>
```

- [ ] It shows a dry run first — review, then type `y`.
- [ ] ~7.8 GB, 15–40 min. If WiFi drops, just run the same command again (it resumes).
- [ ] Carries code + all `.env` secrets; skips node_modules/venvs.

## Phase 6 — Rebuild dependencies (on the Mac, per project)

The skipped folders rebuild with correct Apple-Silicon binaries:

```sh
cd ~/dev/<some-project>
npm install        # or: bun install
# Python projects:
python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt
```

Do this per project as you start working on it — no need to do all at once.

## Phase 7 — Final logins & verification

- [ ] **VS Code** — open it, sign in, enable **Settings Sync** → your 85 extensions + settings return.
- [ ] **Docker** — open Docker.app once to finish its setup.
- [ ] **Claude Code** — run `claude` and log in.
- [ ] **git identity** — `git config --global user.name` should show `huleshjangde`.
- [ ] **.env check** on Mac: `find ~/dev -name '.env' -o -name '.env.local' | grep -v node_modules | wc -l` (~20).
- [ ] Pick one real project, run it end to end (dev server / build) to confirm it works.

## Phase 8 — Only after everything above passes

- [ ] Turn **Remote Login OFF** on the Mac (you only needed it for the transfers).
- [ ] Re-add your **WireGuard** tunnel (WireGuard app from the Mac App Store).
- [ ] Now it's safe to wipe / repurpose the Ubuntu machine.

## Things that work differently on Mac

- Waydroid is gone — your `android*` aliases won't work. Install Android Studio if you need an emulator.
- `xclip` → use built-in `pbcopy` / `pbpaste`.
- `apt`/`snap` → `brew install` / `brew install --cask`.
- `Cmd` replaces `Ctrl` for copy/paste and app shortcuts.
