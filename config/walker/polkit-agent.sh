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

    # NEVER add --exit or --keepopen here. Both make walker 2.16.2 SEGFAULT the
    # `walker --gapplication-service` daemon on teardown (gtk_rb_tree_node_get_previous,
    # via gtk_list_item_manager_remove_items) and return nothing, so every prompt
    # would silently cancel and kill the launcher daemon with it.
    #
    # --height 1 collapses the overall box to its minimum, which is the input field's
    # natural height -- otherwise the (always empty) result list leaves a tall void
    # under the prompt. Not --maxheight, which squashes the input itself, and not
    # --inputonly, which changes nothing here. Longhand only: -h is --help.
    #
    # stdin MUST be detached: walker would otherwise eat the protocol stream.
    pw=$(walker --password --height 1 --placeholder "$prompt" </dev/null) || pw=""

    # Password mode REQUIRES the gapplication-service. Without it walker prints
    # "make sure 'walker --gapplication-service' is running!" on STDOUT -- which,
    # untreated, we would hand to polkit as the password. Refuse instead.
    case "$pw" in
        *"--gapplication-service"*) pw="" ;;
    esac

    if [ -z "$pw" ]; then
        printf '%s\n' '{"action":"cancel"}'
    else
        # Password goes in via a pipe, never argv — argv is world-readable in /proc.
        printf '%s' "$pw" | jq -Rsc '{action:"authenticate",password:.}'
    fi
done
