#!/bin/bash
# Fail if a Brewfile entry no longer resolves: missing, deprecated or disabled
# formula/cask, or a core formula that Homebrew moved elsewhere (e.g. to a cask).
# Usage: check-brewfile.sh [Brewfile]   (bash 3.2 compatible: macOS /bin/bash)
set -euo pipefail

brewfile=${1:-Brewfile}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# `brew bundle list` may print API download progress on stdout: keep entry names only.
list() { brew bundle list "$1" --file="$brewfile" | grep -v -E '^(==>|✔)' || true; }

list --tap >"$tmp/taps"
list --formula >"$tmp/formulae"
list --cask >"$tmp/casks"

# Taps listed in the Brewfile are trusted (`trusted: true`), as `brew bundle` would do.
while read -r tap; do
  brew tap --quiet "$tap"
  if brew trust --help >/dev/null 2>&1; then brew trust --quiet --tap "$tap" >/dev/null; fi
done <"$tmp/taps"

problems=0
report() {
  echo "::error file=$brewfile::$1"
  problems=$((problems + 1))
}

# Existence: one by one, as `brew info` stops at the first unknown name
while read -r f; do
  brew info --formula "$f" >/dev/null 2>&1 || report "formula not found: $f"
done <"$tmp/formulae"
while read -r c; do
  brew info --cask "$c" >/dev/null 2>&1 || report "cask not found: $c"
done <"$tmp/casks"

# Deprecated / disabled, and formulae migrated out of homebrew/core
xargs brew info --json=v2 --formula <"$tmp/formulae" >"$tmp/formulae.json" 2>/dev/null || echo '{}' >"$tmp/formulae.json"
xargs brew info --json=v2 --cask <"$tmp/casks" >"$tmp/casks.json" 2>/dev/null || echo '{}' >"$tmp/casks.json"
curl -fsSL https://formulae.brew.sh/api/formula_tap_migrations.json >"$tmp/migrations.json"

while read -r line; do report "$line"; done < <(
  python3 - "$tmp" <<'PY'
import json, os, sys

tmp = sys.argv[1]
load = lambda name: json.load(open(os.path.join(tmp, name)))
migrations = load("migrations.json")

for f in load("formulae.json").get("formulae", []):
    name = f["full_name"]
    if f.get("disabled"):
        print(f"formula disabled: {name} ({f.get('disable_reason')})")
    elif f.get("deprecated"):
        print(f"formula deprecated: {name} ({f.get('deprecation_reason')})")
    if "/" not in name and name in migrations:
        print(f"formula {name} moved to {migrations[name]}: update the Brewfile")

for c in load("casks.json").get("casks", []):
    if c.get("disabled"):
        print(f"cask disabled: {c['token']} ({c.get('disable_reason')})")
    elif c.get("deprecated"):
        print(f"cask deprecated: {c['token']} ({c.get('deprecation_reason')})")
PY
)

echo "Checked $(wc -l <"$tmp/formulae" | tr -d ' ') formulae and $(wc -l <"$tmp/casks" | tr -d ' ') casks: $problems problem(s)."
[ "$problems" -eq 0 ]
