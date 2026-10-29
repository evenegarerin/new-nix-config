# zsh configuration

ZSH_CONFIG_DIR="${${(%):-%x}:A:h}"

source "$ZSH_CONFIG_DIR/alias.zsh"
source "$ZSH_CONFIG_DIR/progeek.zsh"
source "$ZSH_CONFIG_DIR/fzf.zsh"