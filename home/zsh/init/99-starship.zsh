# Starship must be initialized outside of antidote's static bundle: antidote
# corrupts the prompt into a string literal when starship is loaded as a
# deferred/bundled plugin (https://github.com/starship/starship/issues/7168).
# Sourcing it here, after antidote in oh-my-zsh.zsh, avoids that entirely.

# Remove the default trailing-space gap before right-aligned prompt segments
ZLE_RPROMPT_INDENT=0

eval "$(starship init zsh)"
