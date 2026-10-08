#!/bin/bash
# Bootstrap a new machine: Homebrew, chezmoi source, mise tools, Brewfile, oh-my-zsh, git hooks.
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# chezmoi and mise first: the Brewfile's `go` entries need Go, which mise provides
brew install chezmoi mise

# Point chezmoi at this repo
mkdir -p ~/.config/chezmoi
cat >~/.config/chezmoi/chezmoi.toml <<TOML
sourceDir = "$SCRIPT_DIR"
TOML
echo "chezmoi source set to $SCRIPT_DIR."

# Global tools (go, node, python, npm CLIs). Only the mise config is applied here:
# the full `chezmoi apply` needs the Keychain secrets (see next steps).
chezmoi apply ~/.config/mise/config.toml
mise install
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Packages: formulae, casks, VS Code extensions, Go/uv/krew tools
brew bundle --file="$SCRIPT_DIR/Brewfile"

# Oh-My-Zsh: keep the chezmoi-managed .zshrc, don't start a new shell mid-script
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no KEEP_ZSHRC=yes CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Pre-commit hook guarding against secrets / job-specific content
git -C "$SCRIPT_DIR" config core.hooksPath .githooks

echo "Next steps:"
echo "  1. Store secrets in the macOS Keychain (see README.md), e.g.:"
echo "     chezmoi secret keyring set --service=codestral-api-key --user=\$(whoami) --value=..."
echo "  2. chezmoi apply -v"
echo "  3. Open a new terminal"
echo "Optional (machine-local, never committed; see README.md):"
echo "  - job-specific *.work / work.toml source files"
echo "  - .githooks/blocklist for the pre-commit hook"
