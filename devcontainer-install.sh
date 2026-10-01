#!/usr/bin/env bash

# Entry point for VS Code dotfiles.installCommand, which can't pass arguments.
# There's no TTY to prompt on, so overwrite files the container already has.
exec "$(dirname "$0")/install.sh" --force
