## nix-config

### structure
**configuration.nix**
the uasual entry point to a nixos configuration
it does not define much itself anymore, it imports everything in ./configuration and keeps the handful of options that belong to no topic, nix itself (flakes, garbage collection, store optimise) and the stateVersion

**configuration**
the actual system definition, split into one file per topic e.g. audio.nix, desktop.nix, packages.nix, users.nix
everything in here gets imported by configuration.nix, a new file also needs a new line in that import list
users.nix is also the place where home-manager gets wired in and pointed at home.nix

**hardware-configuration.nix**
contains computer specific information
can be generated via `nixos-generate-config`
located at /etc/nixos/hardware-configuration.nix
configuration/hardware.nix loads it directy from that path, that absolute path outside the repository is the reason every rebuild needs --impure

**flake.nix**
we use flakes (read into it if you feel like it otherwise dont borther with it and just accept that we do)
without flakes configuration.nix would be our entry point to build a configuration, since we use flake the entry point becomes flake.nix
specifies a flake (i named it default since i suck at naming) which we point to with the --flake flag
specefies other flakes we want to use e.g. home-manager
pulls in two nixpkgs, the stable one and nixpkgs-unstable, unstable is handed to the modules as pkgs-unstable for the few programs that want to be newer
points to configuration.nix the entry point without flakes

**flake.lock**
stores versions for every installed program
without out changing flake.lock installed programs will not update on rebuild

**home.nix**
the entypoint to home-manager
home-manager is a flake that we use the configure the home directoy of our users (we only have one user)
same idea as configuration.nix, it imports everything in ./home and keeps only the few settings with no better place, the cursor theme and the xdg user directories

**home**
the home-manager modules, again one file per topic
configLinks.nix is the important one, it does the main thing i use home-manager for, linking out all the configuration specified in this repository, to their required locations

**selfBuild**
nix packages that i build myself, because they are not in nixpkgs or need a change
configuration/packages.nix pulls them in via callPackage

**config**
this directory contains the configurations for all my configured programs
the structure is ./config/[program name]/[everything you want]
they mostly get linked by home-manager places inside the user home directory, some of them are instead read by the system side, e.g. ./config/firefox/policies.json which configuration/firefox.nix reads
configs that are linked via home-manager reflect their change imidiatly in the linked location, configs read by the system side need a rebuild

**skel**
skel is a scaffolding for new projects, which defines how claude code should work in it

**install.md**
is a guide to install the this configuration, on a fresh system

### justfile
**need to be run in the directoy of flake.nix**
`just` on its own lists every recipe with a short description, that list is the source of truth
the recipes already carry the flake output and the --impure, so none of that has to be typed
below are only the few i actually use all the time

in case just is not installed it can be run like this `nix run nixpkgs#just -- [arguments]`.

**just switch**
builds the configuration and activates it right away, this is the normal rebuild
run it after adding a program, after changing anything in ./configuration or ./home, and after an update
when it fails with an error that makes no sense, `just switch-debug` is the same thing with --show-trace and --verbose

**just update**
updates flake.lock, which is what actually moves programs to newer versions
it only changes flake.lock, to get the new programs a `just switch` has to follow
`just upgrade` does both in one go, `just update-input nixpkgs` moves a single input instead of all of them

**just upgrade-preview**
shows what a `just upgrade` would change before you do it, without building anything
first the flake inputs that would move, then how much would be downloaded or built, then the package versions that change
it only evaluates, flake.lock stays untouched, `just upgrade-preview all` shows the unfiltered diff including sources and patches
packages marked insecure upstream are allowed inside the preview so the diff still appears, they are listed by name and a real `just upgrade` still refuses them

**just rollback**
goes back to the previous generation without a reboot, the quickest way out of a broken rebuild
it asks before it does it, `just history` lists the generations if you want to look first
this does not help with the configs in ./config, those are linked out and are not part of a generation (see nice to know)

**just test**
activates the build without writing a grub entry, a reboot puts everything back
good for trying something you are not sure about
`just boot` is the other way around, it makes the build the boot default but leaves the running system alone

### test it out

the whole thing can maybe be tested out by running this `nix run github.com/something#default --impure --option allow-unsafe-native-code-during-evaluation true` or something

### nice to know
super ? shows all hyprland keybinds

? or leader ? often shows keybind in other programs

when someting brakes after nixos rebuild then you can just boot into the older build via grub and everything is on the state before the last rebuild

when something breakes with the configs, specificaly with hyprland its not possible to undo this except for changing the error in the config, since the config is linked out it survices booting into an older version, two possible fixes that both require access to a terminal, git checkout an older commit (before the breaking change), or manually change the file using a tui editor e.g. nano. to get terminal access in a case where hyprland is fully frozen, use "strg + alt + f2" to switch to a different tty manually lot in and fix the config or rename the broken file, after rename it will not get linked to the live config anymore and hyprland should be usable again


### todo, future changes

pdf arranger
eloquent
skanlite

how to properly escape submap since catchall does not seem to work anymore
bug in the current hyprland version; wait for fix

use the last characters (seperator chracter of the statuscolumn) color to convey gitsigns information

rmpc config
