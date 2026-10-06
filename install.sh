#!/usr/bin/env bash

set -euo pipefail

github_user="parched"
with_langs=false
force=false
no_git_config=false

for arg in "$@"; do
  case "$arg" in
    --with-langs) with_langs=true ;;
    --force) force=true ;;
    --no-git-config) no_git_config=true ;;
    *)
      echo "Usage: $0 [--with-langs] [--force] [--no-git-config]" >&2
      exit 1
      ;;
  esac
done

has() { command -v "$1" >/dev/null 2>&1; }

fetch() {
  local url="$1"
  if has curl; then
    curl -fsSL "$url"
  elif has wget; then
    wget -qO- "$url"
  else
    echo "To continue, install curl or wget." >&2
    return 1
  fi
}

bin_dir="$HOME/.local/bin"
chezmoi="$bin_dir/chezmoi"
if [ ! -x "$chezmoi" ]; then
  echo "Installing chezmoi to $bin_dir..."
  fetch "https://chezmoi.io/get" | sh -s -- -b "$bin_dir"
else
  echo "chezmoi is already installed at $chezmoi."
fi

if "$no_git_config"; then
  # Read by .chezmoi.yaml.tmpl when generating the config.
  export DOTFILES_NO_GIT_CONFIG=1
fi

source_dir="$HOME/.local/share/chezmoi"
config="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoi.yaml"
if [ ! -d "$source_dir/.git" ]; then
  echo "Initializing chezmoi with GitHub user '$github_user'..."
  "$chezmoi" init "$github_user"
elif [ ! -f "$config" ]; then
  # Already cloned (e.g. by VS Code dotfiles), so just generate the config.
  echo "Initializing chezmoi from existing checkout at $source_dir..."
  "$chezmoi" init
else
  echo "chezmoi is already initialized."
fi

echo "Applying chezmoi configuration..."
if "$force"; then
  "$chezmoi" apply --force
else
  "$chezmoi" apply --less-interactive
fi

claude="$bin_dir/claude"
if [ ! -x "$claude" ]; then
  echo "Installing Claude Code..."
  fetch "https://claude.ai/install.sh" | bash
else
  echo "Claude Code is already installed at $claude."
fi

os_release="$(. /etc/os-release 2>/dev/null && echo "${ID:-}:${VARIANT_ID:-}")" || true

if [ "$os_release" = "fedora:cosmic-atomic" ]; then
  echo "Adding Flathub remote..."
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  if ! flatpak info com.google.Chrome >/dev/null 2>&1; then
    echo "Installing Google Chrome from Flathub..."
    flatpak install -y --noninteractive flathub com.google.Chrome
  else
    echo "Google Chrome is already installed."
  fi

  echo "Allowing Google Chrome to install PWAs..."
  flatpak override --user \
    --filesystem=~/.local/share/applications:create \
    --filesystem=~/.local/share/icons:create \
    com.google.Chrome

  # PWA .desktop files set Icon= to an absolute path under Chrome's sandbox
  # data dir, but the icons are written to ~/.local/share/icons. flextop only
  # symlinks data/applications to the host, so link data/icons the same way.
  chrome_icons="$HOME/.var/app/com.google.Chrome/data/icons"
  if [ ! -e "$chrome_icons" ]; then
    mkdir -p "$(dirname "$chrome_icons")"
    ln -s "$HOME/.local/share/icons" "$chrome_icons"
  fi

  if [ "$(xdg-settings get default-web-browser 2>/dev/null)" != "com.google.Chrome.desktop" ]; then
    echo "Setting Google Chrome as the default web browser..."
    xdg-settings set default-web-browser com.google.Chrome.desktop
  else
    echo "Google Chrome is already the default web browser."
  fi

  vscode_repo="/etc/yum.repos.d/vscode.repo"
  if [ ! -f "$vscode_repo" ]; then
    echo "Adding VS Code repository..."
    sudo tee "$vscode_repo" >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
  else
    echo "VS Code repository is already added."
  fi

  gcm_version="2.9.1"
  gcm_dir="$HOME/.local/share/gcm"
  gcm="$bin_dir/git-credential-manager"
  if [ "$("$gcm" --version 2>/dev/null | cut -d+ -f1)" != "$gcm_version" ]; then
    case "$(uname -m)" in
      x86_64) gcm_arch="x64" ;;
      aarch64) gcm_arch="arm64" ;;
      *) echo "Unsupported architecture for Git Credential Manager: $(uname -m)" >&2; exit 1 ;;
    esac
    echo "Installing Git Credential Manager $gcm_version to $gcm_dir..."
    rm -rf "$gcm_dir"
    mkdir -p "$gcm_dir" "$bin_dir"
    fetch "https://github.com/git-ecosystem/git-credential-manager/releases/download/v$gcm_version/gcm-linux-$gcm_arch-$gcm_version.tar.gz" \
      | tar -xz -C "$gcm_dir"
    ln -sf "$gcm_dir/git-credential-manager" "$gcm"
  else
    echo "Git Credential Manager $gcm_version is already installed at $gcm."
  fi

  rpm_packages=()
  for package in code; do
    if ! rpm -q "$package" >/dev/null 2>&1; then
      rpm_packages+=("$package")
    else
      echo "$package is already installed."
    fi
  done

  if [ "${#rpm_packages[@]}" -gt 0 ]; then
    echo "Layering ${rpm_packages[*]} with rpm-ostree..."
    rpm-ostree install --idempotent "${rpm_packages[@]}"
    echo "Reboot to finish installing layered packages."
  fi

  # Writes content to a file (as root with --sudo), setting changed=true if it differed.
  update_file() {
    local run=()
    if [ "$1" = "--sudo" ]; then run=(sudo); shift; fi
    local path="$1" content="$2"
    if [ "$(cat "$path" 2>/dev/null)" = "$content" ]; then
      return
    fi
    changed=true
    "${run[@]}" mkdir -p "$(dirname "$path")"
    printf '%s\n' "$content" | "${run[@]}" tee "$path" >/dev/null
  }

  rpm_ostreed_conf="/etc/rpm-ostreed.conf"
  if ! grep -qx 'AutomaticUpdatePolicy=stage' "$rpm_ostreed_conf"; then
    echo "Setting rpm-ostree to stage updates automatically..."
    if grep -qE '^#?AutomaticUpdatePolicy=' "$rpm_ostreed_conf"; then
      sudo sed -i -E 's/^#?AutomaticUpdatePolicy=.*/AutomaticUpdatePolicy=stage/' "$rpm_ostreed_conf"
    else
      sudo sed -i '/^\[Daemon\]/a AutomaticUpdatePolicy=stage' "$rpm_ostreed_conf"
    fi
    if ! grep -qx 'AutomaticUpdatePolicy=stage' "$rpm_ostreed_conf"; then
      echo "Failed to set AutomaticUpdatePolicy in $rpm_ostreed_conf" >&2
      exit 1
    fi
    sudo rpm-ostree reload
  else
    echo "rpm-ostree already stages updates automatically."
  fi

  if ! systemctl is-enabled --quiet rpm-ostreed-automatic.timer; then
    echo "Enabling automatic base image updates..."
    sudo systemctl enable --now rpm-ostreed-automatic.timer
  else
    echo "Automatic base image updates are already enabled."
  fi

  flatpak_timer_unit() {
    cat <<EOF
[Unit]
Description=Daily $1 Flatpak update

[Timer]
OnCalendar=daily
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF
  }

  flatpak_service_unit() {
    cat <<EOF
[Unit]
Description=Update $1 Flatpaks and remove unused runtimes
$2
[Service]
Type=oneshot
ExecStart=/usr/bin/flatpak --$1 update --noninteractive --assumeyes
ExecStart=/usr/bin/flatpak --$1 uninstall --unused --noninteractive --assumeyes
EOF
  }

  system_units="/etc/systemd/system"
  changed=false
  update_file --sudo "$system_units/flatpak-system-update.service" \
    "$(flatpak_service_unit system $'Wants=network-online.target\nAfter=network-online.target\n')"
  update_file --sudo "$system_units/flatpak-system-update.timer" "$(flatpak_timer_unit system)"
  if "$changed"; then
    echo "Installing automatic system Flatpak updates..."
    sudo systemctl daemon-reload
  fi
  if "$changed" || ! systemctl is-enabled --quiet flatpak-system-update.timer; then
    sudo systemctl enable --now flatpak-system-update.timer
  else
    echo "Automatic system Flatpak updates are already enabled."
  fi

  user_units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
  changed=false
  update_file "$user_units/flatpak-user-update.service" "$(flatpak_service_unit user "")"
  update_file "$user_units/flatpak-user-update.timer" "$(flatpak_timer_unit user)"
  if "$changed"; then
    echo "Installing automatic user Flatpak updates..."
    systemctl --user daemon-reload
  fi
  if "$changed" || ! systemctl --user is-enabled --quiet flatpak-user-update.timer; then
    systemctl --user enable --now flatpak-user-update.timer
  else
    echo "Automatic user Flatpak updates are already enabled."
  fi
fi

if "$with_langs"; then
  volta="$HOME/.volta/bin/volta"
  if [ ! -x "$volta" ]; then
    echo "Installing Volta..."
    fetch "https://get.volta.sh" | bash -s -- --skip-setup
    echo "Installing Node.js with Volta..."
    "$volta" install node
  else
    echo "Volta is already installed at $volta."
  fi

  uv="$HOME/.local/bin/uv"
  if [ ! -x "$uv" ]; then
    echo "Installing uv..."
    fetch "https://astral.sh/uv/install.sh" | sh
  else
    echo "uv is already installed at $uv."
  fi

  dotnet="$HOME/.dotnet/dotnet"
  if [ ! -x "$dotnet" ]; then
    echo "Installing .NET SDK..."
    fetch "https://dot.net/v1/dotnet-install.sh" | bash
  else
    echo ".NET SDK is already installed at $dotnet."
  fi
fi
