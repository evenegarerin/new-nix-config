zmodload zsh/datetime
autoload -Uz add-zsh-hook
setopt prompt_subst

typeset -g PROMPT_DURATION_THRESHOLD=3
typeset -g _prompt_cmd_start=""
typeset -g _prompt_cmd_duration=""

_prompt_fmt_duration() {
  local LC_NUMERIC=C
  local -F t=$1
  local -i i ms
  (( i = t + 0.5 ))
  (( ms = t * 1000 + 0.5 ))

  if (( t < 1 )); then
    printf '%dms' $ms
  elif (( t < 9.95 )); then
    printf '%.1fs' $t
  elif (( i < 60 )); then
    printf '%ds' $i
  elif (( i < 3600 )); then
    printf '%dm%02ds' $(( i / 60 )) $(( i % 60 ))
  else
    printf '%dh%02dm' $(( i / 3600 )) $(( (i % 3600) / 60 ))
  fi
}

_prompt_timer_preexec() {
  _prompt_cmd_start=$EPOCHREALTIME
}

_prompt_timer_precmd() {
  local -F elapsed

  if [[ -n $_prompt_cmd_start ]]; then
    (( elapsed = EPOCHREALTIME - _prompt_cmd_start ))
    _prompt_cmd_start=""

    if (( elapsed >= PROMPT_DURATION_THRESHOLD )); then
      _prompt_cmd_duration="%{$FG[214]%}$(_prompt_fmt_duration $elapsed)%{$reset_color%} "
      return
    fi
  fi

  _prompt_cmd_duration=""
}

add-zsh-hook preexec _prompt_timer_preexec
add-zsh-hook precmd _prompt_timer_precmd

RPS1="%(?..%{$fg[red]%}%? ↵%{$reset_color%} )"
RPS1+='${_prompt_cmd_duration}'
if (( $+functions[virtualenv_prompt_info] )); then
  RPS1+='$(virtualenv_prompt_info)'
fi
RPS1+="${FG[237]}%n@%m%{$reset_color%}"
