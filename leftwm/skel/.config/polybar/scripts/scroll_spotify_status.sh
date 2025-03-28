#!/bin/bash

# credit: https://github.com/PrayagS/polybar-spotify

# see man zscroll for documentation of the following parameters
ps aux | grep "/opt/spotify/spotify" | grep -v grep && zscroll -l 18 \
        --delay 0.1 \
        --scroll-padding "  " \
        --match-command "$HOME/.config/leftwm/themes/current/polybar/scripts/get_spotify_status.sh" \
        --match-text "Playing" "--scroll 1" \
        --match-text "Paused" "--scroll 0" \
        --update-check true "$HOME/.config/leftwm/themes/current/polybar/scripts/get_spotify_status.sh" &

wait
