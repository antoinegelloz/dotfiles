# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). Source files live here as `dot_*`
(chezmoi renders them into `$HOME` on `chezmoi apply`). `private_dot_zshrc.tmpl` is a
template: secrets are pulled from the macOS Keychain at render time via
chezmoi's `keyring` template function, never stored in this repo.

## New machine setup

```sh
./install.sh      # Homebrew + Brewfile, oh-my-zsh, chezmoi source, git hooks
chezmoi apply -v
mise install      # node & npm tools from ~/.config/mise/config.toml
```

Refresh the package list with `brew bundle dump --file=Brewfile --force`
(drop the `npm` lines: npm tools are managed by mise).

## Secrets

These services must exist in the macOS Keychain before `apply` (see
`private_dot_zshrc.tmpl` for where each is used):

| service             | used for            |
|----------------------|----------------------|
| `codestral-api-key`  | `CODESTRAL_API_KEY`  |

Set one with:

```sh
chezmoi secret keyring set --service=<service> --user=$(whoami) --value=<value>
```

## Making changes

Edit files in this repo directly (chezmoi's source dir is configured to point
here, see `~/.config/chezmoi/chezmoi.toml`), then run `chezmoi diff` /
`chezmoi apply` to sync `$HOME`.

## Job-specific config

Work-only settings live in git-ignored source files, so chezmoi deploys them on
this machine but they are never pushed:

| source                              | target                        | used by                     |
|-------------------------------------|-------------------------------|-----------------------------|
| `private_dot_zshrc.work.tmpl`       | `~/.zshrc.work`               | sourced by `~/.zshrc`       |
| `dot_gitconfig.work`                | `~/.gitconfig.work`           | included by `~/.gitconfig`  |
| `private_dot_ssh/private_config.work` | `~/.ssh/config.work`        | included by `~/.ssh/config` |
| `dot_config/mise/conf.d/work.toml`  | `~/.config/mise/conf.d/work.toml` | loaded by mise          |

Each is optional: delete them (source and target) when leaving the job.

## Pre-commit hook

`.githooks/pre-commit` (enabled by `install.sh` via `core.hooksPath`) blocks a
commit if `gitleaks` finds a secret, or if added lines match a regex from
`.githooks/blocklist`, a local git-ignored list of job-specific strings.
