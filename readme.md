## nix-config

### structure
**configuration.nix**
the uasual entry point to a nixos configuration
it defines the entire system

**hardware-configuration.nix**
contains computer specific information
can be generated via `nixos-generate-config`
located at /etc/nixos/hardware-configuration.nix
our configuration.nix loads it directy from that path

**flake.nix**
we use flakes (read into it if you feel like it otherwise dont borther with it and just accept that we do)
without flakes configuration.nix would be our entry point to build a configuration, since we use flake the entry point becomes flake.nix
specifies a flake (i named it default since i suck at naming) which we point to with the --flake flag
specefies other flakes we want to use e.g. home-manager
points to configuration.nix the entry point without flakes

**flake.lock**
stores versions for every installed program
without out changing flake.lock installed programs will not update on rebuild

**home.nix**
the entypoint to home-manager
home-manager is a flake that we use the configure the home directoy of our users (we only have one user)
the main use i use home-manager for is to link out all the configuration specified in this repository, to their required locations

**config**
this directory contains the configurations for all my configured programs
the structure is ./config/[program name]/[everything you want]
they mostly get linked by home-manager places inside the user home directory, some of those config files need to be linked outside of home, which is then handled by configuration.nix
configs that are linked via home-manager reflect their change imidiatly in the linked location, configs linked via configuration.nix need a rebuild

**skel**
skel is a scaffolding for new projects, which defines how claude code should work in it

**intall.md**
is a guide to install the this configuration, on a fresh system

### commands
**need to be run in the directoy of flake.nix**
rebuild (install newly added programs or reflect other changes)
`sudo nixos-rebuild switch --flake .#default --impure`

update (update flake.lock)
`nix flake update`
(update only changes flake.lock, to actually get the programs, you need to rebuild afterwards again)

### nice to know
super ? shows all hyprland keybinds

? or leader ? often shows keybind in other programs


### todo, future changes

pdf arranger
eloquent
skanlite

how to properly escape submap since catchall does not seem to work anymore
bug in the current hyprland version; wait for fix

take a look at this: -> https://github.com/jdhao/nvim-config

lazy git                                        -- custom config
neovim config
quick shell (bar)                               -- no
dentritic nixos config

marquee in waybar in white text, and behind everything else
maybe yes quick shell ???

in the special workspace make windows that are not focuses transparent (invisible, dont render them)

change default time for hyprland notification, or make it so that they stay present if my mouse is over them                            -- maybe not possible

walker clipboard history

