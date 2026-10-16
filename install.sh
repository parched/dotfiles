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

# Read by .chezmoi.yaml.tmpl when generating the config.
if "$no_git_config"; then
  export DOTFILES_NO_GIT_CONFIG=1
fi
if "$with_langs"; then
  export DOTFILES_WITH_LANGS=1
fi

source_dir="$HOME/.local/share/chezmoi"
if [ ! -d "$source_dir/.git" ]; then
  echo "Initializing chezmoi with GitHub user '$github_user'..."
  "$chezmoi" init "$github_user"
else
  # Already cloned (e.g. by VS Code dotfiles), so just (re)generate the config
  # in case flags have changed. Answers to earlier prompts are kept.
  echo "Initializing chezmoi from existing checkout at $source_dir..."
  "$chezmoi" init
fi

echo "Applying chezmoi configuration..."
if "$force"; then
  "$chezmoi" apply --force
else
  "$chezmoi" apply --less-interactive
fi
