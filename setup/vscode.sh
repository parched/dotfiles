#!/bin/bash

set -euo pipefail

extensions=(
    "ms-python.python"
    "esbenp.prettier-vscode"
    "dbaeumer.vscode-eslint"
    "eamodio.gitlens"
    "streetsidesoftware.code-spell-checker"
    "redhat.vscode-yaml"
    "github.copilot"
    "vscodevim.vim"
)

for extension in "${extensions[@]}"
do
    echo "Installing $extension"
    code --install-extension $extension
done