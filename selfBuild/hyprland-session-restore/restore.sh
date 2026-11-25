#!/usr/bin/env bash
set -euo pipefail

source="$STATE_DIRECTORY/last-session.json"
[[ -s $source ]] || exit 0

filter=$(cat <<'EOF'
def sq: "'" + gsub("'"; "'\\''") + "'";

def exe:
  split("/") | last
  | if test("^\\..*-wrapped$") then .[1:-8] else . end;

def ws:
  if .id > 0 then (.id | tostring)
  elif (.name | startswith("special:")) then .name
  else "name:" + .name
  end;

def ws_lua:
  if .id > 0 then (.id | tostring) else (ws | @json) end;

def target_monitor($saved):
  ($monitors | map(select(.id == $saved)) | first) // ($monitors | last)
  | .name;

($monitors | sort_by(.id)) as $monitors
| map(select(.workspace.type == "normal"))
| group_by(.pid)
| map(.[0])
| map(select(.argv | length > 0))
| sort_by(.workspace.id, .floating, .at[0], .at[1])
| .[]
| (([.argv[0] | exe] + .argv[1:]) | map(sq) | join(" ")) as $cmd
| ({workspace: ((.workspace | ws) + " silent")}
   + if .floating then
       {float: true, size: "\(.size[0]) \(.size[1])", move: "\(.at[0]) \(.at[1])"}
     else {} end) as $rules
| target_monitor(.monitor) as $monitor
| [
    (.pid | tostring),
    (.workspace | ws_lua),
    $monitor,
    "hl.exec_cmd(\($cmd | @json), {\($rules | to_entries | map("\(.key) = \(.value | @json)") | join(", "))})"
  ]
| join("\u001f")
EOF
)

addresses() {
  hyprctl clients -j | jq -r '.[].address' | sort
}

monitors=$(hyprctl monitors -j | jq -c 'map({id, name})')
active_ws=$(hyprctl activeworkspace -j | jq -r '.id')

old_split=$(hyprctl -j getoption dwindle:force_split | jq .int)
trap 'hyprctl eval "hl.config({ dwindle = { force_split = $old_split } })" >/dev/null' EXIT
hyprctl eval 'hl.config({ dwindle = { force_split = 2 } })' >/dev/null

placed=" "
declare -A restored

while IFS=$'\x1f' read -r pid ws monitor lua; do
  before=$(addresses)
  if ! hyprctl eval "$lua" >/dev/null; then
    echo "failed: $lua" >&2
    continue
  fi
  for _ in $(seq 40); do
    new=$(comm -13 <(echo "$before") <(addresses) | head -n1)
    if [[ -n $new ]]; then
      restored[$pid]=$new
      break
    fi
    sleep 0.5
  done

  if [[ -n $monitor && $placed != *" $ws "* ]]; then
    hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = $ws }))" >/dev/null
    hyprctl eval "hl.dispatch(hl.dsp.workspace.move({ monitor = $(jq -n --arg m "$monitor" '$m | @json') }))" >/dev/null
    placed+="$ws "
  fi
done < <(jq -r --argjson monitors "$monitors" "$filter" "$source")

focus_address=""
for pid in $(jq -r 'sort_by(.focusHistoryID) | .[].pid' "$source"); do
  if [[ -n ${restored[$pid]:-} ]]; then
    focus_address=${restored[$pid]}
    break
  fi
done

if [[ -n $focus_address ]]; then
  hyprctl eval "for _, w in ipairs(hl.get_windows()) do if w.address == \"$focus_address\" then hl.dispatch(hl.dsp.focus({ window = w })) end end" >/dev/null
else
  hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = $active_ws }))" >/dev/null
fi
