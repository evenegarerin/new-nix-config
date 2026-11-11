# NixOS configuration tasks. Run `just` to see all recipes.

set positional-arguments

# Flake output to build (override with `just host=laptop switch`)
host := "default"
rebuild := "sudo nixos-rebuild --flake .#" + host + " --impure"
profile := "/nix/var/nix/profiles/system"

# List available recipes
default:
    @just --list --unsorted

# --- Rebuild ---

# Build and activate the configuration now, then show what changed
switch *args:
    #!/usr/bin/env bash
    set -euo pipefail
    old=$(readlink -f /run/current-system)
    {{ rebuild }} switch "$@"
    nvd diff "$old" /run/current-system

# Build and activate, with full trace for debugging errors
switch-debug *args:
    #!/usr/bin/env bash
    set -euo pipefail
    old=$(readlink -f /run/current-system)
    {{ rebuild }} switch --show-trace --verbose "$@"
    nvd diff "$old" /run/current-system

# Build and make it the boot default, but don't activate until reboot
boot *args:
    #!/usr/bin/env bash
    set -euo pipefail
    {{ rebuild }} boot "$@"
    nvd diff /run/current-system {{ profile }}

# Activate temporarily without adding a boot entry (reverts on reboot)
test *args:
    #!/usr/bin/env bash
    set -euo pipefail
    old=$(readlink -f /run/current-system)
    {{ rebuild }} test "$@"
    nvd diff "$old" /run/current-system

# Show what would be built or fetched, without building
dry *args:
    nixos-rebuild dry-build --flake .#{{ host }} --impure "$@"

# --- Update ---

# Update all flake inputs (flake.lock)
update:
    nix flake update

# Update a single flake input, e.g. `just update-input nixpkgs`
update-input input:
    nix flake update "$1"

# Update all inputs, then switch to the result
upgrade: update switch

# Show what `just upgrade` would change, without building (pass "all" for the unfiltered diff)
upgrade-preview mode="brief":
    #!/usr/bin/env bash
    set -euo pipefail
    tmp=$(mktemp -d)
    trap 'pkill -P $$ >/dev/null 2>&1 || true; rm -rf "$tmp"' EXIT
    toplevel='.#nixosConfigurations.{{ host }}.config.system.build.toplevel'
    instantiate() {
        local out=$1 insecure=$2
        shift 2
        if [[ "$insecure" == allow ]]; then
            export NIXPKGS_ALLOW_INSECURE=1
        fi
        nix path-info --derivation --impure "$@" "$toplevel" > "$out" 2> "$out.err"
    }
    nix flake update --output-lock-file "$tmp/flake.lock"
    locked() { jq -r '.nodes | to_entries[] | select(.value.locked) | "\(.key) \(.value.locked.rev // .value.locked.narHash) \(.value.locked.lastModified // 0)"' "$1"; }
    locked flake.lock > "$tmp/oldinputs"
    locked "$tmp/flake.lock" > "$tmp/newinputs"
    changed=0
    while read -r name rev stamp; do
        oldline=$(grep -E "^$name " "$tmp/oldinputs" || true)
        [[ -z "$oldline" ]] && continue
        read -r _ oldrev oldstamp <<< "$oldline"
        [[ "$oldrev" == "$rev" ]] && continue
        changed=1
        printf '%-20s %s (%s) -> %s (%s)\n' "$name" "${oldrev:0:9}" "$(date -d "@$oldstamp" +%F)" "${rev:0:9}" "$(date -d "@$stamp" +%F)"
    done < "$tmp/newinputs"
    if (( ! changed )); then
        echo "all flake inputs are already up to date"
        exit 0
    fi
    echo "evaluating both systems ..."
    instantiate "$tmp/old" allow &
    oldpid=$!
    instantiate "$tmp/new" allow --reference-lock-file "$tmp/flake.lock" &
    newpid=$!
    instantiate "$tmp/probe" strict --reference-lock-file "$tmp/flake.lock" &
    probepid=$!
    for job in old:$oldpid new:$newpid; do
        if ! wait "${job#*:}"; then
            cat "$tmp/${job%%:*}.err" >&2
            exit 1
        fi
    done
    old=$(< "$tmp/old")
    new=$(< "$tmp/new")
    echo
    if ! wait "$probepid"; then
        bad=$(sed -n 's/.*Refusing to evaluate package \(.*\) in \/nix\/store.*/\1/p' "$tmp/probe.err" | tr -d "'\`" | sed "s/[‘’]//g" | sort -u)
        if [[ -n "$bad" ]]; then
            echo "marked insecure, allowed for this preview only:"
            sed 's/^/  /' <<< "$bad"
            echo "a real just upgrade stops here until nixpkgs.config.permittedInsecurePackages allows them"
            echo
        fi
    fi
    if [[ "$old" == "$new" ]]; then
        echo "inputs moved, but the system would be identical"
        exit 0
    fi
    nix build --dry-run "$new^out" 2>&1 | grep -E 'will be (built|fetched)' || true
    echo
    if [[ "{{ mode }}" == "all" ]]; then
        nix store diff-closures "$old" "$new"
    else
        nix store diff-closures "$old" "$new" \
            | sed 's/\.drv//g' \
            | grep -vE '\.(tar\.[a-z0-9]+|tgz|zip|patch|diff)\b' \
            | grep -vE '^[^ :]*(-src|-source|-vendor|-vendor-staging|-bootstrap): '
    fi

# Check the flake evaluates and its checks pass
check:
    nix flake check --impure

# --- Generations & cleanup ---

# List system generations
history:
    sudo nix-env --list-generations --profile {{ profile }}

# Show package changes across the last N system generations (default 5)
changes count="5":
    #!/usr/bin/env bash
    set -euo pipefail
    current=$(readlink {{ profile }} | tr -dc '0-9')
    first=$(( current - $1 + 1 ))
    if (( first < 1 )); then first=1; fi
    nvd history -p {{ profile }} -m "$first"

# Roll back to the previous generation
[confirm("Roll back to the previous system generation?")]
rollback:
    #!/usr/bin/env bash
    set -euo pipefail
    old=$(readlink -f /run/current-system)
    sudo nixos-rebuild switch --rollback
    nvd diff "$old" /run/current-system

# Delete generations older than N days and collect garbage (default 7)
[confirm("Delete old generations and garbage-collect the Nix store?")]
gc days="7":
    sudo nix-collect-garbage --delete-older-than "$1d"

# Deduplicate files in the Nix store to save space
optimise:
    sudo nix-store --optimise
