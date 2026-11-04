#!/usr/bin/env bash
# Bridge between cmd-polkit and walker. Line-delimited JSON both ways:
#   in : {"action":"request password","prompt":…,"message":…,"polkit action":{…}}
#   out: {"action":"authenticate","password":…}  or  {"action":"cancel"}
#   in : {"action":"authorization response","authorized":bool}
# Never add `set -x` here — the password passes through this script.
set -u

while IFS= read -r msg; do
    [ "$(printf '%s' "$msg" | jq -r '.action // empty')" = "request password" ] || continue

    prompt=$(printf '%s' "$msg" | jq -r '.prompt // "Password"' | sed 's/: *$//')

    # --exit is REQUIRED: with the walker service running, a dmenu call without it
    # fails with "GDBus.Error...NoReply: Remote peer disconnected" and returns nothing.
    # stdin MUST be detached: walker would otherwise eat the protocol stream.
    pw=$(walker --password --exit --placeholder "$prompt" </dev/null) || pw=""

    if [ -z "$pw" ]; then
        printf '%s\n' '{"action":"cancel"}'
    else
        # Password goes in via a pipe, never argv — argv is world-readable in /proc.
        printf '%s' "$pw" | jq -Rsc '{action:"authenticate",password:.}'
    fi
done
