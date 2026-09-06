## Hello

Thank you for trying d77void wasp edition.

This ISO uses wasp — a dwl fork (dwm for Wayland) with a live-reloadable
Lua config (no recompile needed, just `mod+shift+r`) — together with
Quickshell (Utumno, my quickshell approach for wasp), driven through the
same qsd77 CLI as the qsd77 edition.

To install use Calamares from the menu.

## Keybinds

alt + shift + return -> terminal

alt + p -> menu

alt + comma -> scratchpad terminal

alt + j / alt + k -> focus next/previous window

alt + shift + j / alt + shift + k -> swap window next/previous

alt + t / alt + f / alt + m / alt + r -> tile / floating / monocle / dwindle layout

alt + shift + space -> toggle floating

alt + space -> cycle layout

alt + h / alt + l -> shrink/grow master column

alt + i / alt + d -> increase/decrease master count

alt + 1..9 -> focus workspace

alt + shift + 1..9 -> move window to workspace

super + space -> launcher

super + r -> d77run

super + t -> lock screen

super + x -> session menu

super + y -> wallpaper picker

alt + shift + r -> reload config

alt + shift + q -> quit wasp

## wasp tweaks

To alter the autostart programs, add/swap keybinds and keyboard layout
configure ~/.config/wasp/config.lua ; the file is self explanatory and
with several examples already configured.

Have fun!
