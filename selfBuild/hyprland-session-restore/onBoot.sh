#!/usr/bin/env bash
set -euo pipefail

saved="$STATE_DIRECTORY/clients.json"
snapshot="$STATE_DIRECTORY/last-session.json"
skip="$(dirname "$0")/skip.sh"

if [[ ! -s $saved ]] || [[ $(jq 'map(select(.workspace.type == "normal")) | length' "$saved") -eq 0 ]]; then
  bash "$skip"
  exit 0
fi

cp "$saved" "$snapshot"

summary=$(jq -r '
  map(select(.workspace.type == "normal"))
  | group_by(.workspace.name)
  | map("ws \(.[0].workspace.name)  \(map(.class) | unique | join(", "))")
  | join("\n")
' "$snapshot")

while pgrep -x hyprlock >/dev/null; do
  sleep 1
done

for _ in $(seq 30); do
  if qs ipc call sessionRestore ask "$summary" 2>/dev/null; then
    exit 0
  fi
  sleep 1
done

echo "quickshell did not answer, session restore prompt not shown" >&2
bash "$skip"
