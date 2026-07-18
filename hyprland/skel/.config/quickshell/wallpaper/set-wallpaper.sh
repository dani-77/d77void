#!/usr/bin/env bash
# set-wallpaper.sh - Compositor-agnostic wallpaper tool for Quickshell

STATE_FILE="$HOME/.cache/quickshell/wallpaper/current"

detect_compositor() {
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        echo "hyprland"
    elif [ -n "$SWAYSOCK" ]; then
        echo "sway"
    else
        echo "generic"
    fi
}

detect_focused_monitor() {
    local comp=$(detect_compositor)
    if [ "$comp" = "hyprland" ]; then
        if command -v hyprctl >/dev/null 2>&1; then
            hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .name' 2>/dev/null
        fi
    elif [ "$comp" = "sway" ]; then
        if command -v swaymsg >/dev/null 2>&1; then
            swaymsg -t get_outputs | jq -r '.[] | select(.focused==true) | .name' 2>/dev/null
        fi
    fi
}

apply_wallpaper() {
    local path="$1"
    local mon="$2"
    
    if [ -z "$path" ] || [ ! -f "$path" ]; then
        echo "Error: Invalid wallpaper path: $path" >&2
        exit 1
    fi
    
    # Save the path to state file for persistence
    mkdir -p "$(dirname "$STATE_FILE")"
    echo -n "$path" > "$STATE_FILE"
    
    local comp=$(detect_compositor)
    
    # If monitor is empty, try to detect the focused one
    if [ -z "$mon" ]; then
        mon=$(detect_focused_monitor)
    fi
    
    case "$comp" in
        hyprland)
            if command -v hyprctl >/dev/null 2>&1; then
                # If monitor is still empty, hyprpaper uses empty monitor (comma + path) to apply to all
                local target_mon="$mon"
                hyprctl hyprpaper wallpaper "$target_mon, $path" 2>/dev/null
                if [ $? -ne 0 ]; then
                    hyprctl hyprpaper preload "$path" >/dev/null 2>&1
                    hyprctl hyprpaper wallpaper "$target_mon, $path" >/dev/null 2>&1
                fi
            fi
            ;;
        sway)
            if command -v swaymsg >/dev/null 2>&1; then
                if [ -z "$mon" ]; then
                    mon="*"
                fi
                swaymsg output "$mon" bg "$path" fill >/dev/null 2>&1
            fi
            ;;
        *)
            # Fallback to general tools like swww or feh if installed
            if command -v swww >/dev/null 2>&1; then
                swww img "$path" >/dev/null 2>&1
            elif command -v swaybg >/dev/null 2>&1; then
                pkill swaybg
                swaybg -i "$path" -m fill >/dev/null 2>&1 &
            elif command -v feh >/dev/null 2>&1; then
                feh --bg-fill "$path"
            fi
            ;;
    esac
}

clear_wallpaper() {
    rm -f "$STATE_FILE"
    local comp=$(detect_compositor)
    case "$comp" in
        hyprland)
            if command -v hyprctl >/dev/null 2>&1; then
                hyprctl hyprpaper unload all >/dev/null 2>&1 || true
            fi
            ;;
        sway)
            if command -v swaymsg >/dev/null 2>&1; then
                swaymsg output "*" bg "none" >/dev/null 2>&1 || true
            fi
            ;;
        *)
            if command -v swww >/dev/null 2>&1; then
                swww clear >/dev/null 2>&1 || true
            else
                pkill swaybg || true
            fi
            ;;
    esac
    return 0
}

startup() {
    if [ -f "$STATE_FILE" ]; then
        local path=$(cat "$STATE_FILE")
        if [ -f "$path" ]; then
            apply_wallpaper "$path" ""
        fi
    fi
}

COMMAND="$1"
shift

case "$COMMAND" in
    apply)
        apply_wallpaper "$@"
        ;;
    clear)
        clear_wallpaper
        ;;
    startup)
        startup
        ;;
    *)
        echo "Usage: $0 {apply <path> [monitor]|clear|startup}" >&2
        exit 1
        ;;
esac
