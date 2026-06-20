# PATH — first entry has highest priority
path=(
    $HOME/.local/bin
    $HOME/.local/share/cargo/bin(N/)
    $HOME/bin(N/)
    $HOME/.bun/bin(N/)
    $HOME/.ghcup/bin(N/)
    $HOME/.opencode/bin(N/)
    $HOME/.pyenv/bin(N/)
    $HOME/.terragrunt/bin(N/)
    $path
)
typeset -U path
