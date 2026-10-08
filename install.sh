#!/bin/bash
set -euo pipefail

# Install Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install chezmoi if missing
if ! command -v chezmoi >/dev/null 2>&1; then
  brew install chezmoi
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<TOML
sourceDir = "$SCRIPT_DIR"
TOML

echo "chezmoi source set to $SCRIPT_DIR."
echo "Before applying, store personal secrets in the macOS Keychain, e.g.:"
echo "  chezmoi secret keyring set --service=linode-token --user=\$(whoami) --value=..."
echo "See README.md for the full list of expected secrets."
echo "Then run: chezmoi apply -v"
