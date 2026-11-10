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
