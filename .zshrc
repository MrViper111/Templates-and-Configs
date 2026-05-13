export PATH="/opt/homebrew/bin:/usr/local/Cellar/:/usr/local/opt/:/usr/local/bin/:$PATH"
export PATH="/opt/homebrew/bin:$PATH"

export PATH="/Library/PostgreSQL/18/bin:$PATH"

eval "$(starship init zsh)"

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

eval "$(fzf --zsh)"

bindkey '^F' autosuggest-accept
