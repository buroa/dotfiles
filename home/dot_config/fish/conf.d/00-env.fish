set -gx KUBE_EDITOR nvim
set -gx VISUAL nvim
set -gx EDITOR nvim
set -gx GOPATH $HOME/.go
set -gx ANSIBLE_FORCE_COLOR true
set -gx ANSIBLE_HOST_KEY_CHECKING False
set -gx PY_COLORS true
status is-interactive; and set -gx GPG_TTY (tty)
set -gx LANG en_US.utf-8

fish_add_path --global $HOME/.local/bin
fish_add_path --global $HOME/.cargo/bin
fish_add_path --global $HOME/.krew/bin
fish_add_path --global $HOME/.go/bin
