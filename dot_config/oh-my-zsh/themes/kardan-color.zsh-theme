# kardan, with colors: a short prompt on the left, context on the right.
#
#   ❯                   ✘ 1  (⎈|context:namespace) ~/dotfiles (main ✗) @host
#
# %F{n}…%f sets/resets the foreground color (0-255, see `spectrum_ls`), %B…%b bold.

# Prompt char: green after a successful command, red after a failure.
PROMPT='%(?.%F{cyan}.%F{red})%B❯%b%f '

# Exit code (only when non-zero), kubectl context, cwd, git branch and state, short hostname.
RPROMPT='%(?..%F{red}✘ %?%f  )$(kube_ps1)%F{cyan}%~%f$(git_prompt_info) %F{242}@%m%f'

# kube-ps1 plugin: hidden without a context (`kubeoff`/`kubeon` toggle it per shell).
# The trailing space lives in the suffix so nothing is left over when it's hidden.
KUBE_PS1_HIDE_IF_NOCONTEXT=true
KUBE_PS1_PREFIX_COLOR=242
KUBE_PS1_SUFFIX=") "
KUBE_PS1_SUFFIX_COLOR=242
KUBE_PS1_CTX_COLOR=cyan
KUBE_PS1_NS_COLOR=cyan
# A context without a namespace means kubectl uses "default": show that, not "N/A".
_kube_ps1_ns() { [[ $1 == N/A ]] && echo default || echo $1 }
KUBE_PS1_NAMESPACE_FUNCTION=_kube_ps1_ns

ZSH_THEME_GIT_PROMPT_PREFIX=" %F{242}(%F{cyan}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%F{242})%f"
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{cyan}✗"
ZSH_THEME_GIT_PROMPT_CLEAN=" %F{cyan}✓"
