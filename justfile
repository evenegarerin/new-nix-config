# NixOS configuration tasks. Run `just` to see all recipes.

set positional-arguments

# Flake output to build (override with `just host=laptop switch`)
host := "default"
rebuild := "sudo nixos-rebuild --flake .#" + host + " --impure"

# List available recipes
default:
    @just --list --unsorted

# --- Rebuild ---

# Build and activate the configuration now (extra flags pass through)
switch *args:
    {{ rebuild }} switch "$@"

# Build and activate, with full trace for debugging errors
switch-debug *args:
    {{ rebuild }} switch --show-trace --verbose "$@"

# Build and make it the boot default, but don't activate until reboot
boot *args:
    {{ rebuild }} boot "$@"

# Activate temporarily without adding a boot entry (reverts on reboot)
test *args:
    {{ rebuild }} test "$@"

# Build the configuration without activating it
build *args:
    nixos-rebuild build --flake .#{{ host }} --impure "$@"

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
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Roll back to the previous generation
[confirm("Roll back to the previous system generation?")]
rollback:
    sudo nixos-rebuild switch --rollback

# Delete generations older than N days and collect garbage (default 7)
[confirm("Delete old generations and garbage-collect the Nix store?")]
gc days="7":
    sudo nix-collect-garbage --delete-older-than "$1d"

# Deduplicate files in the Nix store to save space
optimise:
    sudo nix-store --optimise
