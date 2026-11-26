#!/usr/bin/env bash
set -euo pipefail

target="$STATE_DIRECTORY/clients.json"
tmp="$target.tmp"

clients=$(hyprctl clients -j)

argvs='{}'
while read -r pid title; do
  [[ -r /proc/$pid/cmdline ]] || continue
  if [[ $title == kitty ]] && cmd=$(bash "$(dirname "$0")/kitty.sh" "$pid"); then
    words=()
    eval "words=($cmd)"
    argv=$(printf '%s\0' "${words[@]}" | jq -Rsc 'rtrimstr("\u0000") | split("\u0000")')
  else
    argv=$(jq -Rsc 'rtrimstr("\u0000") | split("\u0000")' < "/proc/$pid/cmdline")
  fi
  argvs=$(jq -c --arg pid "$pid" --argjson argv "$argv" '. + {($pid): $argv}' <<< "$argvs")
done < <(jq -r '.[] | "\(.pid) \(.initialTitle)"' <<< "$clients" | sort -u)

jq --argjson argvs "$argvs" 'map(. + {argv: ($argvs[.pid | tostring] // [])})' <<< "$clients" > "$tmp"
mv "$tmp" "$target"

for f in "$STATE_DIRECTORY"/nvim/*.vim; do
  [[ -e $f ]] || continue
  grep -qF "$f" "$target" "$STATE_DIRECTORY/last-session.json" 2>/dev/null || rm -f "$f"
done
