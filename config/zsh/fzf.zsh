# extra keybind for fzf

export FZF_DEFAULT_OPTS="--bind 'alt-k:up,alt-j:down'"
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group '<' '>'
