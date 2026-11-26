#!/usr/bin/env bash
set -euo pipefail

read -r tpgid < <(ps -o tpgid= --ppid "$1" | awk '$1 > 0 { print $1; exit }') || {
  echo "kitty $1 has no child with a terminal" >&2
  exit 1
}
fgp=$tpgid
[[ -d /proc/$fgp ]] || fgp=$(pgrep -g "$tpgid" -n)

mapfile -d '' kitty_argv < "/proc/$1/cmdline"
class=""
for (( i = 1; i < ${#kitty_argv[@]}; i++ )); do
  case ${kitty_argv[i]} in
    --) break ;;
    --class) class=${kitty_argv[i+1]}; break ;;
    --class=*) class=${kitty_argv[i]#--class=}; break ;;
  esac
done

kitty=$(printf 'kitty --directory %q' "$(readlink "/proc/$fgp/cwd")")
[[ -n $class ]] && kitty+=$(printf ' --class %q' "$class")

if [[ $(< "/proc/$fgp/comm") =~ ^(zsh|bash|sh|dash|fish|nu|ksh)$ ]]; then
  echo "$kitty"
  exit
fi

mapfile -d '' argv < "/proc/$fgp/cmdline"
exe=${argv[0]##*/}
[[ $exe =~ ^\.(.*)-wrapped$ ]] && exe=${BASH_REMATCH[1]}
if [[ ${argv[0]} == /nix/store/* ]] && wrapper=$(command -v "$exe"); then
  flags=()
  if line=$(grep -F "\"${argv[0]}\"" "$wrapper" 2>/dev/null); then
    rest=${line##*\""${argv[0]}"\"}
    eval "flags=(${rest%\"\$@\"*})"
  fi
  n=${#flags[@]}
  [[ "${argv[*]:1:n}" == "${flags[*]}" ]] || n=0
  argv=("$exe" "${argv[@]:1+n}")
fi

if [[ $exe == nvim ]]; then
  sock=""
  for p in "$fgp" $(pgrep -P "$fgp"); do
    s="${XDG_RUNTIME_DIR:-/tmp}/nvim.$p.0"
    [[ -S $s ]] || s=$(find "${TMPDIR:-/tmp}" -type s -name "nvim.$p.*" 2>/dev/null | head -n1 || true)
    if [[ -S $s ]]; then
      sock=$s
      break
    fi
  done
  session="$STATE_DIRECTORY/nvim/$fgp-$(awk '{print $22}' "/proc/$fgp/stat").vim"
  mkdir -p "${session%/*}"
  if [[ -n $sock ]] && timeout 5 nvim --server "$sock" --remote-expr "execute('mksession! ' . fnameescape('$session'))" >/dev/null; then
    argv=(nvim -S "$session")
  fi
fi

quoted=$(printf '%q ' "${argv[@]}")
echo "$kitty -- ${quoted% }"
