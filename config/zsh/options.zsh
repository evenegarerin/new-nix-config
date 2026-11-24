setopt auto_cd

HISTSIZE=50000
SAVEHIST=10000
setopt hist_ignore_dups
setopt hist_ignore_space

zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

for keymap in viins vicmd; do
  bindkey -M $keymap '^[[A' up-line-or-beginning-search
  bindkey -M $keymap '^[OA' up-line-or-beginning-search
  bindkey -M $keymap '^[[B' down-line-or-beginning-search
  bindkey -M $keymap '^[OB' down-line-or-beginning-search
  bindkey -M $keymap '^[[1;5C' forward-word
  bindkey -M $keymap '^[[1;5D' backward-word
done
unset keymap
