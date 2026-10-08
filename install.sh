#!/bin/bash
# Bootstrap a new machine: Homebrew + packages, oh-my-zsh, chezmoi source, git hooks.
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Packages (includes chezmoi, mise, fzf, gitleaks...)
brew bundle --file="$SCRIPT_DIR/Brewfile"

# Oh-My-Zsh: keep the chezmoi-managed .zshrc, don't start a new shell mid-script
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no KEEP_ZSHRC=yes CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Point chezmoi at this repo
mkdir -p ~/.config/chezmoi
cat >~/.config/chezmoi/chezmoi.toml <<TOML
sourceDir = "$SCRIPT_DIR"
TOML
echo "chezmoi source set to $SCRIPT_DIR."

# Pre-commit hook guarding against secrets / job-specific content
git -C "$SCRIPT_DIR" config core.hooksPath .githooks

echo "Next steps:"
echo "  1. Store secrets in the macOS Keychain (see README.md), e.g.:"
echo "     chezmoi secret keyring set --service=codestral-api-key --user=\$(whoami) --value=..."
echo "  2. chezmoi apply -v"
echo "  3. mise install"
echo "Optional (machine-local, never committed; see README.md):"
echo "  - job-specific *.work / work.toml source files"
echo "  - .githooks/blocklist for the pre-commit hook"
