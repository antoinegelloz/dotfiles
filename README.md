# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). Source files live here as `dot_*`
(chezmoi renders them into `$HOME` on `chezmoi apply`). `dot_zshrc.tmpl` is a
template: secrets are pulled from the macOS Keychain at render time via
chezmoi's `keyring` template function, never stored in this repo.

## New machine setup

```sh
./install.sh
chezmoi apply -v
```

## Secrets

These three services must exist in the macOS Keychain before `apply` (see
`dot_zshrc.tmpl` for where each is used):

| service             | used for            |
|----------------------|----------------------|
| `codestral-api-key`  | `CODESTRAL_API_KEY`  |
| `gitlab-token`       | `GITLAB_TOKEN`       |
| `linode-token`       | `LINODE_TOKEN`       |

Set one with:

```sh
chezmoi secret keyring set --service=<service> --user=$(whoami) --value=<value>
```

## Making changes

Edit files in this repo directly (chezmoi's source dir is configured to point
here, see `~/.config/chezmoi/chezmoi.toml`), then run `chezmoi diff` /
`chezmoi apply` to sync `$HOME`.
