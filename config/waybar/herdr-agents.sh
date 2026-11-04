#!/usr/bin/env bash

# Waybar module showing the state of the agents running in the herdr server.
#
#   status  emit waybar JSON: one dot coloured by the most urgent agent,
#           tooltip listing every agent with its own coloured dot
#   notify  ask hyprland to toast a per-state tally of the agents
#
# With no agents (or no running server) `status` emits empty text so waybar
# collapses the module.

set -uo pipefail

# Shared jq helpers. `rank` orders the states by urgency, `color` maps them onto
# the bar palette, `esc` makes arbitrary agent titles safe for the pango markup
# used in the tooltip.
jq_prelude='
  def rank:  {"blocked":4,"done":3,"working":2,"idle":1,"unknown":0}[.] // 0;
  def icon:  {"blocked":0,"done":5,"working":1,"idle":2,"unknown":2}[.] // 2;
  def color: {
    "blocked":"#f38ba8",
    "done":"#a6e3a1",
    "working":"#f9e2af",
    "idle":"#6c7086",
    "unknown":"#45475a"
  }[.] // "#45475a";
  def esc: gsub("&";"&amp;") | gsub("<";"&lt;") | gsub(">";"&gt;");
  def agents: .result.agents // [];
  def by_urgency: sort_by(.agent_status | rank) | reverse;
'

cmd_status() {
  local out
  out=$(herdr agent list 2>/dev/null | jq -c "$jq_prelude"'
    agents as $a
    | if ($a | length) == 0 then
        {text: ""}
      else
        ($a | by_urgency) as $s
        | {
            text: "󰧑",
            class: $s[0].agent_status,
            tooltip: ($s | map(
              "<span color=\"\(.agent_status | color)\">󰧑</span>  "
              + "\(.cwd | split("/") | last | esc) — \(.terminal_title_stripped | esc)"
            ) | join("\n"))
          }
      end
  ' 2>/dev/null)

  # herdr unreachable, or jq choked on unexpected output: hide the module rather
  # than leaving waybar showing a stale dot.
  [ -n "$out" ] && printf '%s\n' "$out" || printf '{"text":""}\n'
}

cmd_notify() {
  #!/usr/bin/env bash
# herdr-jump: raise the window running herdr

for p in $(pgrep -x herdr); do
  parent=$(ps -o ppid= -p $p)
  grand=$(ps -o ppid= -p $parent)
  addr=$(hyprctl clients -j | jq -r ".[] | select(.pid==$parent or .pid==$grand) | .address")
  [ -n "$addr" ] && exec hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })"
done
}

case "${1:-status}" in
  status) cmd_status ;;
  notify) cmd_notify ;;
  *)
    echo "usage: ${0##*/} [status|notify]" >&2
    exit 1
    ;;
esac
