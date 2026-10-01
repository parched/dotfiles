#!/usr/bin/env bash

# Entry point for VS Code dotfiles.installCommand, which can't pass arguments.
# There's no TTY to prompt on, so overwrite files the container already has.
# VS Code copies the host's git config, but only if the file doesn't exist yet.
exec "$(dirname "$0")/install.sh" --force --no-git-config
