# PATH — first entry has highest priority
path=(
    $HOME/.local/bin
    $HOME/bin(N/)
    $HOME/.cargo/bin(N/)
    $HOME/.terragrunt/bin(N/)
    $HOME/.local/share/fnm/aliases/default/bin(N/)
    $path
)
typeset -U path
