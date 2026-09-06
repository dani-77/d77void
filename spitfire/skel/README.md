## Hello

Thank you for trying d77void spitfire edition.

This ISO uses spitfire — a dwm-spirited tiling Wayland compositor with a
live-reloadable Lua config (no recompile needed, just `spitfirectl reload`)
— together with Quickshell (Utumno, my quickshell approach for spitfire),
driven through the same qsd77 CLI as the qsd77 edition.

To install use Calamares from the menu.

## Keybinds

super + return -> terminal

super + s -> scratchpad terminal

super + q -> close window

super + j / super + k -> focus next/previous window

super + shift + j / super + shift + k -> swap window next/previous

super + t / super + f / super + m -> tile / fibonacci / monocle layout

super + shift + space -> floating layout

super + space -> cycle layout

super + h / super + l -> shrink/grow master column

super + i / super + d -> increase/decrease master count

super + 1..9 -> focus workspace

alt + 1..9 -> move window to workspace

super + a -> launcher

super + r -> d77run

super + x -> session menu

super + y -> wallpaper picker

super + z -> lock screen

super + shift + r -> reload config

super + shift + q -> quit spitfire

## spitfire tweaks

To alter the autostart programs, add/swap keybinds and keyboard layout
configure ~/.config/spitfire/config.lua ; the file is self explanatory and
with several examples already configured.

Have fun!
