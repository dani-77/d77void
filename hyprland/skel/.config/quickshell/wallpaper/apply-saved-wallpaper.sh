#!/bin/sh
# apply-saved-wallpaper.sh
#
# Writes the last wallpaper chosen via the Quickshell wallpaper picker
# directly into hyprpaper.conf, BEFORE hyprpaper starts. This way
# hyprpaper launches already showing the right wallpaper, instead of
# briefly showing the configured default and then switching via IPC.
#
# Run this from hyprland.conf BEFORE "exec-once = hyprpaper":
#   exec-once = sh ~/.config/quickshell/wallpaper/apply-saved-wallpaper.sh
#   exec-once = hyprpaper
#
# Rewrites only the "preload" line and the "wallpaper { ... }" block.
# Every other line in hyprpaper.conf (splash, etc.) is left untouched.
# monitor is always left empty (applies to all monitors); fit_mode is
# always "fill".
#
# Written in plain POSIX sh: no seq, no fractional sleep, no bashisms.

STATE_FILE="$HOME/.cache/quickshell/wallpaper/current"
CONF_FILE="$HOME/.config/hypr/hyprpaper.conf"

WALLPAPER=""
if [ -f "$STATE_FILE" ]; then
    WALLPAPER="$(cat "$STATE_FILE")"
    [ -f "$WALLPAPER" ] || WALLPAPER=""
fi

mkdir -p "$(dirname "$CONF_FILE")"
[ -f "$CONF_FILE" ] || touch "$CONF_FILE"

TMP_FILE="$(mktemp)"

# Strip the existing "preload = ..." line and the whole
# "wallpaper { ... }" block, keep everything else untouched. Runs
# unconditionally: if the state was cleared (no WALLPAPER), this leaves
# hyprpaper.conf with no preload/wallpaper block, so hyprpaper starts
# blank and the backdrop takes over instead of re-showing a stale
# wallpaper from before the last clear.
awk '
    /^[[:space:]]*preload[[:space:]]*=/ { next }
    /^[[:space:]]*wallpaper[[:space:]]*\{/ { in_block = 1; next }
    in_block && /^[[:space:]]*\}/ { in_block = 0; next }
    in_block { next }
    { print }
' "$CONF_FILE" > "$TMP_FILE"

if [ -n "$WALLPAPER" ]; then
    # Prepend the fresh preload line + wallpaper block.
    {
        printf 'preload = %s\n' "$WALLPAPER"
        printf 'wallpaper {\n'
        printf '\tmonitor =\n'
        printf '\tpath = %s\n' "$WALLPAPER"
        printf '\tfit_mode = fill\n'
        printf '}\n'
        printf '\n'
        cat "$TMP_FILE"
    } | awk 'NF{blank=0} !NF{blank++} blank<2' > "$CONF_FILE"
    rm -f "$TMP_FILE"
else
    mv "$TMP_FILE" "$CONF_FILE"
fi
