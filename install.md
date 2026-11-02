## installation

Die Anleitung funktioniert sowohl mit der grafischen als auch der minimalen nixos install-iso.
Wir nutzen für alle Schritte eh das Terminal.

Nicht alle der Schritte sind immer erforderlich, z.B. deutsches keyboard layout laden. Wenn klar ist das ein Schrit nicht gebraucht wird ihn überspringen. Die Faustregel ist, im Zweifel wird der Schrit gebraucht und nicht übersprungen.

Für jedes Kapitel gibt es ein Beispiel wie es aus dem Terminal gemacht werden kann, manche sachen wie z.B. das setzen der Partitionen lässt sich auch mit Grafischen Anwendungen machen, nimm was immer du willst.


> die konfiguration hat ein paar dinge fest verdrahtet, die vor oder nach der installation angepasst werden sollten:
> - benutzer `castle` (`configuration.nix`)
> - hostname `thinkpad` (`configuration.nix`)
> - `nixConfig = "/home/castle/nix-config/config"` (`home.nix`) — wenn der benutzer umbenannt wird, muss das hier mit umbenannt werden

### 0. Vorbereitung

* Grafischen Installer schließen, das ding brauchen wir nicht.
* Terminal öffnen, das ding brauchen wir.
* root werden `sudo -i`
* deutsches keyboard layout laden `loadkeys de`

### 1. Netzwerk herstellen

* Im Terminal `nmcli` starten
* "Activate a connection" wählen
* Netzwerk auswählen
* Spam Escape um nmcli zu verlassen
* Mit `ping google.com` testen

### 2. Flakes in der installer-shell aktivieren

Die iso hat flakes standardmäßig nicht aktiviert.

```sh
export NIX_CONFIG="experimental-features = nix-command flakes"
```

### 3. Festplatte auswählen

Hier genau hinschauen, schritt 4 löscht alles von der Festplatte.

```sh
lsblk
```

```sh
# sata und nvme benennen die partitionen unterschiedlich, deshalb beides vorab setzen
export DISK=/dev/nvme0n1          # oder /dev/sda
export P=p                        # "p" bei nvme (nvme0n1p1), "" bei sata (sda1)
```

### 4. Festplatte partitionieren

Drei Partitionen:

| # | größe       | typ        | zweck                                              |
|---|-------------|------------|----------------------------------------------------|
| 1 | 1 GiB       | EFI (ef00) | `/boot` — grub + kernel + initrd, unverschlüsselt   |
| 2 | halber ram  | swap       | swap, bei jedem boot mit zufälligem schlüssel verschlüsselt |
| 3 | rest        | luks       | luks-container mit dem root-dateisystem             |


```sh
# swap = die hälfte des verbauten rams, in MiB
export SWAP_MIB=$(( $(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 / 2 ))
echo "swap wird ${SWAP_MIB} MiB groß"

sgdisk --zap-all "$DISK"
sgdisk -n 1:0:+1G             -t 1:ef00 -c 1:boot      "$DISK"
sgdisk -n 2:0:+${SWAP_MIB}M   -t 2:8200 -c 2:swap      "$DISK"
sgdisk -n 3:0:0               -t 3:8309 -c 3:cryptroot "$DISK"

partprobe "$DISK"
lsblk "$DISK"
```

### 5. Verschlüsseln und Formatieren

luks2 auf partition 3, darauf dann die dateisysteme.
Die passphrase, die hier gesetzt wird nicht vergessen, das wäre schade.

```sh
cryptsetup luksFormat --type luks2 "${DISK}${P}3"      # YES tippen, dann die passphrase zweimal
cryptsetup open "${DISK}${P}3" cryptroot               # wird als /dev/mapper/cryptroot entsperrt

mkfs.fat -F32 -n boot "${DISK}${P}1"
mkswap -L swap "${DISK}${P}2"
mkfs.ext4 -L nixos /dev/mapper/cryptroot
```

### 6. Alles einhängen

```sh
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot
mount -o umask=077 "${DISK}${P}1" /mnt/boot
swapon "${DISK}${P}2"
```

### 7. hardware-konfiguration erzeugen

`configuration.nix` importiert `/etc/nixos/hardware-configuration.nix` über einen **absoluten pfad**.
Die datei muss also auch auf der live-iso unter `/etc/nixos/` liegen — kopieren reicht.

```sh
nixos-generate-config --root /mnt/root

mkdir -p /etc/nixos
cp /mnt/etc/nixos/hardware-configuration.nix /etc/nixos/hardware-configuration.nix
```

prüfen, ob das luks-gerät erkannt wurde — es sollte eine zeile wie
`boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/...";` enthalten.

Fehlt die luks-zeile, dann ist das ein Problem, in dem Fall ein trusted adult um hilfe fragen.

### 8. Zweimal installieren.

Home Manager nutzt absolute Pfade um sym links zu erstellen, diese links werden nach der installation nicht funktionieren, dafür müssen wir nach dem Installieren noch mal rebuilden.

* Falls git nicht installiert ist, git so hohlen `nix-shell -p git`
* Die config so clonen `git clone https://github.com/evenegarerin/new-nix-config`
* Umbenennen `mv new-nix-config nix-config`

* Falls die config schon vorhanden ist muss git vor dem installieren trotzem hinzugefügt werden.

* In das Configurations Verzeichniss gehen `cd nix-config`.
* Erste Installation `nixos-install --flake /mnt/home/castle/nix-config#default --impure --root /mnt/root`
* Die config in das Home Verzeichnis kopieren `cp -r ../nix-config /mnt/root/home/castle/nix-config`, change castle wenn der username anders ist.
* Dann chroot in das instalierte system `chroot /mnt`
* Und geh in das Configurations Verzeichnis `cd /home/castle/nix-config`, change castle wenn der username anders ist.
* Rebuild `sudo nixos-rebuild switch --flake .#default --impure`, danach funktionieren alle sym links

### 9. Erster Start

* `reboot`
* wenn hyprland nicht started dann kann mit alt ctrl F2 in eine andere tty gewächselt werden.
* von hier kann die diagnose selbst versucht werden, sonnst ein trusted adult um hilfe bitten.

### nach der installation

sudo ist in dieser konfiguration auf `Defaults rootpw` gesetzt, **sudo fragt also nach dem root-passwort, nicht nach dem eigenen**.
beide konten haben noch das initiale passwort `password`, das sollte jetzt geändert werden.

* Füre `passwd` im Terminal aus
* Dann `sudo -i`
* Und wieder `passwd`
* Und `exit`

* Prüfe ob die sym links funktioniert haben `ls -l ~/.config/hypr`
* Falls der link in leere zeigt, füre die folgenden beiden befehle aus `cd ~/nix-config`
* `sudo nixos-rebuild switch --flake .#default --impure`
