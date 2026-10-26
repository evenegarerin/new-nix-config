#!/bin/sh

mode_file="$XDG_RUNTIME_DIR/launcher-mode"
mode=$(cat "$mode_file" 2>/dev/null || echo normal)
rm -f "$mode_file"

cache="${XDG_CACHE_HOME:-$HOME/.cache}/desktop-execs"

app_dirs() (
    IFS=:; set -f
    for d in ${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}; do
        [ -d "$d/applications" ] && printf '%s\n' "$d/applications"
    done
)

# Rebuild if the cache is missing or any applications dir changed since
if [ ! -f "$cache" ] || app_dirs | while IFS= read -r d; do
        find "$d" -type d -newer "$cache"
    done | grep -q .; then
    mkdir -p "${cache%/*}"
    app_dirs | while IFS= read -r d; do
        find -L "$d" -type f -name '*.desktop' -exec awk '
            FNR == 1 { e = 0 }
            /^\[/ { e = ($0 == "[Desktop Entry]"); next }
            e && /^Exec[ \t]*=/ {
                c = $0
                sub(/^Exec[ \t]*=[ \t]*/, "", c); sub(/\r$/, "", c)
                gsub(/%%/, "\001", c); gsub(/%[fFuUdDnNickvm]/, "", c); gsub(/\001/, "%", c)
                gsub(/[ \t]+/, " ", c); sub(/^ /, "", c); sub(/ $/, "", c)
                print c
            }' {} +
    done | sort -u > "$cache.tmp" && mv "$cache.tmp" "$cache"
fi

if [ "$mode" = new-workspace ] && grep -Fxq -- "$*" "$cache"; then
    echo new-workspace-confirm > "$mode_file"
fi

exec hyprctl eval "hl.dispatch(hl.dsp.exec_cmd([[$*]]))"
