#!/usr/bin/env bash

set -euo pipefail

github_user="parched"

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
