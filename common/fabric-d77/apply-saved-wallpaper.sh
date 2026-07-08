#!/bin/sh
# apply-saved-wallpaper.sh (fabric-d77 / awww)
#
# Applies the last wallpaper chosen in the picker (wallpaper_selector.py) as
# soon as awww-daemon starts, or paints the Backdrop colBg if none is saved
# (or "Clear" was used). Unlike hyprpaper, awww has no config file to
# pre-load before the daemon starts: everything is done via IPC commands to
# a running daemon, so this script must run AFTER "awww-daemon" in exec-once
# and waits for the socket to be ready before sending the command.
#
# Run this from hyprland config, AFTER "awww-daemon -l background":
#   exec-once = awww-daemon -l background
#   exec-once = sh ~/.config/fabric-d77/apply-saved-wallpaper.sh
#
# Written in plain POSIX sh: no seq, no fractional sleep, no bashisms.

STATE_FILE="$HOME/.cache/fabric-d77/wallpaper/current"
CLEAR_COLOR="1a1b26"

# Wait for the awww-daemon socket to be ready (it starts in parallel via a
# separate exec-once and may not have initialized yet).
i=0
while [ "$i" -lt 10 ]; do
    awww query >/dev/null 2>&1 && break
    i=$((i + 1))
    sleep 1
done

WALLPAPER=""
if [ -f "$STATE_FILE" ]; then
    WALLPAPER="$(cat "$STATE_FILE")"
    [ -f "$WALLPAPER" ] || WALLPAPER=""
fi

if [ -n "$WALLPAPER" ]; then
    awww img "$WALLPAPER"
else
    awww clear "$CLEAR_COLOR"
fi
