#!/usr/bin/env bash

set -euo pipefail

github_user="parched"
with_langs=false

if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != "--with-langs" ]; }; then
  echo "Usage: $0 [--with-langs]" >&2
  exit 1
fi

if [ "$#" -eq 1 ]; then
  with_langs=true
fi

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

if [ ! -d "$HOME/.local/share/chezmoi/.git" ]; then
  echo "Initializing chezmoi with GitHub user '$github_user'..."
  "$chezmoi" init "$github_user"
else
  echo "chezmoi is already initialized."
fi

echo "Applying chezmoi configuration..."
"$chezmoi" apply --less-interactive

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

  rpm_packages=()
  for package in code git-credential-libsecret; do
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
