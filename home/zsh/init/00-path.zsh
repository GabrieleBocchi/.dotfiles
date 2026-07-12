# PATH — first entry has highest priority
path=(
    $HOME/.local/bin
    $HOME/bin(N/)
    $HOME/.cargo/bin(N/)
    $HOME/.opencode/bin(N/)
    $HOME/.pyenv/bin(N/)
    $HOME/.terragrunt/bin(N/)
    $path
)
typeset -U path
