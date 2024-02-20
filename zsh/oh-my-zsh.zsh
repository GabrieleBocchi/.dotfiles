# Load Antigen
source /usr/share/zsh/share/antigen.zsh

# Load oh-my-zsh
antigen use oh-my-zsh

# Load plugins
antigen bundle git
antigen bundle colored-man-pages
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle ssh-agent

# Load theme
antigen theme robbyrussell

# Load SSH identities
zstyle :omz:plugins:ssh-agent identities ~/.ssh/$SSH_IDENTITIES

# Apply changes
antigen apply
