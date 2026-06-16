#!/usr/bin/env bash
# ===========================================================================
#  Run this ON YOUR MACBOOK to set up remote access to the Ubuntu laptop
#  (Dell G15 5530, Tailscale IP 100.104.253.72).
#
#  Usage:  bash setup-mac-access.sh
# ===========================================================================
set -euo pipefail

# --- Connection details for the Ubuntu laptop (already configured) ----------
HOST_IP="100.104.253.72"        # Tailscale IP of the Ubuntu laptop
HOST_USER="hulesh"              # login user on the Ubuntu laptop
NX_PORT="4000"                  # NoMachine port
TAILSCALE_ACCOUNT="huleshjangde1@   (sign in with the SAME account)"

echo "==> Setting up MacBook to reach $HOST_USER@$HOST_IP"

# --- 1. Homebrew (the macOS package manager) --------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Homebrew not found. Installing it..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Make brew available in this shell (Apple Silicon vs Intel paths)
  if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
  if [ -x /usr/local/bin/brew ];  then eval "$(/usr/local/bin/brew shellenv)";  fi
else
  echo "==> Homebrew already installed."
fi

# --- 2. Tailscale (mesh VPN — reaches the laptop through any network) -------
echo "==> Installing Tailscale (GUI app)..."
brew install --cask tailscale-app 2>/dev/null || brew install --cask tailscale

# --- 3. NoMachine client (graphical remote desktop) -------------------------
echo "==> Installing NoMachine client..."
brew install --cask nomachine

# --- 4. Save a one-tap SSH shortcut -----------------------------------------
echo "==> Adding an SSH shortcut 'ssh laptop' to ~/.ssh/config ..."
mkdir -p "$HOME/.ssh"
if ! grep -q "Host laptop" "$HOME/.ssh/config" 2>/dev/null; then
  cat >> "$HOME/.ssh/config" <<EOF

Host laptop
    HostName $HOST_IP
    User $HOST_USER
EOF
fi

# --- 5. Final instructions --------------------------------------------------
cat <<EOF

============================================================
 DONE on the MacBook. Two manual steps remain:

 1. Open the **Tailscale** app (menu bar) and SIGN IN with:
        $TAILSCALE_ACCOUNT
    Wait until it shows "Connected".

 2. Connect to the laptop:
    • Desktop (GUI):  open the **NoMachine** app -> Add a connection
                      Host: $HOST_IP   Port: $NX_PORT
                      log in as user "$HOST_USER" with your Ubuntu password.
    • Terminal:       ssh laptop          (shortcut just added)
                      or:  ssh $HOST_USER@$HOST_IP

 TIP: do this test once while you are still on the same network as the
 laptop, to confirm it all works before you travel.
============================================================
EOF
