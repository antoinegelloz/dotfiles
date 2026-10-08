# dotfiles

My macOS dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

This repo is chezmoi's **source directory**: `chezmoi apply` renders its files
into `$HOME`. The repo is public, so it holds no secrets and no job-specific
settings: secrets come from the macOS Keychain, and work config lives in
git-ignored files (see [Job-specific config](#job-specific-config)).

## What's inside

| Source                           | Target in `$HOME`               | Purpose                                                        |
| -------------------------------- | ------------------------------- | -------------------------------------------------------------- |
| `private_dot_zshrc.tmpl`         | `~/.zshrc` (0600)               | Interactive zsh: PATH, oh-my-zsh, mise, fzf, aliases, secrets  |
| `dot_zprofile`                   | `~/.zprofile`                   | Login shells: Homebrew, mise shims, app-installed CLIs         |
| `dot_zshenv`                     | `~/.zshenv`                     | Every zsh: disables Apple Terminal per-tab sessions            |
| `dot_gitconfig`                  | `~/.gitconfig`                  | Git: SSH signing, GitHub over SSH, sane defaults               |
| `dot_config/git/ignore`          | `~/.config/git/ignore`          | Global gitignore                                               |
| `dot_config/git/allowed_signers` | `~/.config/git/allowed_signers` | Verifies my SSH-signed commits locally                         |
| `private_dot_ssh/private_config` | `~/.ssh/config` (0600)          | SSH defaults; includes OrbStack and job-specific hosts         |
| `dot_config/mise/config.toml`    | `~/.config/mise/config.toml`    | Global tool versions: node, python, npm CLIs                   |
| `dot_config/gh/config.yml`       | `~/.config/gh/config.yml`       | GitHub CLI settings (auth stays in `hosts.yml`, not tracked)   |
| `dot_config/zed/settings.json`   | `~/.config/zed/settings.json`   | Zed editor settings                                            |
| `dot_vimrc`                      | `~/.vimrc`                      | Vim                                                            |
| `.chezmoiexternal.toml`          | `~/.vim/pack/plugins/start/…`   | Third-party checkouts chezmoi keeps updated (vim-go)           |
| `Brewfile`                       | —                               | Homebrew formulae, casks, VS Code extensions, Go/uv/krew tools |
| `install.sh`                     | —                               | New machine bootstrap                                          |
| `.mise.toml`, `.github/`         | —                               | Lint tasks and CI (see [Checks and CI](#checks-and-ci))        |
| `.githooks/pre-commit`           | —                               | Blocks commits containing secrets or job-specific strings      |

`dot_` becomes a leading `.`, `private_` makes the target readable only by me,
and `.tmpl` files are rendered as [templates](https://www.chezmoi.io/user-guide/templating/).

## New machine setup

```sh
git clone git@github.com:antoinegelloz/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh   # Homebrew + Brewfile, oh-my-zsh, chezmoi source dir, git hooks
```

Then:

1. Store the [secrets](#secrets) in the Keychain.
2. Optionally recreate the [job-specific files](#job-specific-config) and the
   [hook blocklist](#pre-commit-hook): they are not in the repo.
3. `chezmoi apply -v`
4. `mise install` (node, python and npm tools)
5. Open a new terminal.

## Day-to-day

| To…                                     | Run                                                                                       |
| --------------------------------------- | ----------------------------------------------------------------------------------------- |
| Edit `~/.zshrc`                         | `zshrc` (alias for `chezmoi edit --apply ~/.zshrc`)                                       |
| Edit any other managed file             | Edit it here, then `chezmoi diff` and `chezmoi apply`                                     |
| Keep a change an app made to its config | `chezmoi re-add` (e.g. after `mise use -g`, `gh config set`, Zed settings UI)             |
| Check for drift                         | `chezmoi status` (should print nothing)                                                   |
| Update the package list                 | `brew bundle dump --file=Brewfile --force`, then drop the `npm` lines (mise manages them) |
| Change a global tool version            | `mise use -g python@3.14.8`, then `chezmoi re-add`                                        |

Editing a deployed file directly (e.g. `vim ~/.zshrc`) works until the next
`chezmoi apply`, which overwrites it: always go through the source here.

## Secrets

Secrets are read from the macOS Keychain when chezmoi renders a template, so
they only exist in the rendered files in `$HOME` (mode 0600), never in this repo.

| Keychain service    | Used for            | Template                 |
| ------------------- | ------------------- | ------------------------ |
| `codestral-api-key` | `CODESTRAL_API_KEY` | `private_dot_zshrc.tmpl` |

Job-specific templates may use more entries (see below). Set one with:

```sh
chezmoi secret keyring set --service=<service> --user=$(whoami) --value=<value>
```

## Job-specific config

Work settings live in source files matched by `.gitignore` (`*.work`,
`*.work.tmpl`, `work.toml`): chezmoi deploys them on this machine, but git
never commits them. Each managed file loads its work counterpart only if it
exists:

| Source (git-ignored)                  | Target                            | Loaded by                        |
| ------------------------------------- | --------------------------------- | -------------------------------- |
| `private_dot_zshrc.work.tmpl`         | `~/.zshrc.work`                   | sourced at the end of `~/.zshrc` |
| `dot_gitconfig.work`                  | `~/.gitconfig.work`               | `[include]` in `~/.gitconfig`    |
| `private_dot_ssh/private_config.work` | `~/.ssh/config.work`              | `Include` in `~/.ssh/config`     |
| `dot_config/mise/conf.d/work.toml`    | `~/.config/mise/conf.d/work.toml` | mise (all `conf.d/*.toml`)       |

These files exist only on the work machine and are not backed up by this repo.

When leaving a job:

1. Delete the files above, both here and in `$HOME`.
2. Delete the Keychain entries their templates use.
3. Delete job-specific leftovers outside chezmoi (e.g. `~/.ssh/known_hosts.*`,
   `~/.aws/credentials`).
4. Keep `.githooks/blocklist`: it keeps protecting the repo afterwards.

## Pre-commit hook

`.githooks/pre-commit` (enabled by `install.sh` with
`git config core.hooksPath .githooks`) refuses a commit when:

- [gitleaks](https://github.com/gitleaks/gitleaks) finds a secret in the staged
  changes (known false positives go in `.gitleaksignore`), or
- an added line matches a pattern from `.githooks/blocklist`.

The blocklist is git-ignored, since publishing it would reveal what it
protects. It holds one case-insensitive extended regex per line, with `#`
comments:

```text
# Employer-specific strings
acme ?corp
\.acme\.internal
```

## Checks and CI

`mise run lint` runs every check with the tool versions pinned in `.mise.toml`:
ShellCheck and shfmt, Prettier, actionlint, gitleaks over the full history,
and the blocklist over tracked files. The same command runs in GitHub Actions:

- **Lint** (`.github/workflows/lint.yml`): on every push to `main` and on pull
  requests. The blocklist comes from the `BLOCKLIST` repository secret; failures
  print only `file:line`, since workflow logs are public. Update the secret after
  editing the local blocklist:

  ```sh
  gh secret set BLOCKLIST < .githooks/blocklist
  ```

- **Brewfile** (`.github/workflows/brewfile.yml`): weekly on macOS, and when
  the `Brewfile` changes. Fails if an entry was removed, deprecated, disabled or
  moved (e.g. a formula that became a cask). Run it locally with
  `.github/scripts/check-brewfile.sh`.

CI only reports problems once they are pushed: the pre-commit hook remains the
guard that keeps them out of the public history.

## Not managed here

- **VS Code**: settings, keybindings, extensions and MCP servers sync through
  VS Code Settings Sync (GitHub account). Extensions are also listed in the
  `Brewfile` for bootstrapping.
- **oh-my-zsh**: installed by `install.sh`, updates itself.
- **Credentials**: SSH keys, `~/.aws`, `gh` auth (`hosts.yml`).
