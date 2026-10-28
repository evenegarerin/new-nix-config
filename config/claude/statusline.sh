#!/usr/bin/env bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // .model.id // "?"')
used=$(echo "$input"  | jq -r '.context_window.used_percentage // 0')
size=$(echo "$input"  | jq -r '.context_window.context_window_size // 0')
in=$(echo "$input"    | jq -r '.context_window.total_input_tokens // 0')
out=$(echo "$input"   | jq -r '.context_window.total_output_tokens // 0')
cost=$(echo "$input"  | jq -r '.cost.total_cost_usd // 0')

# color the context % green/yellow/red
if   (( ${used%.*} >= 80 )); then c='\033[31m'
elif (( ${used%.*} >= 50 )); then c='\033[33m'
else                               c='\033[32m'; fi

printf "%s | ctx: ${c}%.0f%%\033[0m (%dk/%dk) | \$%.2f" \
  "$model" "$used" $((in/1000 + out/1000)) $((size/1000)) "$cost"