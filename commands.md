## rebuild command, just incase i forget
sudo nixos-rebuild switch --flake .#default --impure

## update command
nix flake update
afterwards rebuild again to apply updates