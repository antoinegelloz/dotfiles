# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). Source files live here as `dot_*`
(chezmoi renders them into `$HOME` on `chezmoi apply`). `private_dot_zshrc.tmpl` is a
template: secrets are pulled from the macOS Keychain at render time via
chezmoi's `keyring` template function, never stored in this repo.

## New machine setup

```sh
./install.sh
chezmoi apply -v
```

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

Work-only settings live in `*.work` / `*.work.tmpl` source files (e.g.
`private_dot_zshrc.work.tmpl` → `~/.zshrc.work`, `dot_gitconfig.work` →
`~/.gitconfig.work`). They are git-ignored, so chezmoi deploys them on this
machine but they are never pushed. `~/.zshrc` sources and `~/.gitconfig`
includes them only if present.
