# ~/.zshrc

###############################################################################
# oh-my-zsh
###############################################################################

export ZSH=/usr/share/oh-my-zsh

# bootstrap oh-my-zsh if it is not present
if [ ! -d "$ZSH" ]; then
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH"
fi

ZSH_THEME="af-magic"

plugins=(
  command-not-found
  git
  history
  sudo
)

source "$ZSH/oh-my-zsh.sh"

###############################################################################
# Aliases
###############################################################################

alias code="codium"

###############################################################################
# Functions
###############################################################################

# yazi shell wrapper that cd's into the directory you quit in
function yy() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

###############################################################################
# Syntax highlighting (must be sourced last)
###############################################################################

if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

function sudo2()
{
    su admin -c "sudo $*" # it would be better to not hard code the name of the wheel user here
}