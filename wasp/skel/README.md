## Hello

Thank you for trying d77void wasp edition.

This ISO uses wasp — a dwl fork (dwm for Wayland) with a live-reloadable
Lua config (no recompile needed, just `mod+shift+r`) — together with
Quickshell (Utumno, my quickshell approach for wasp), driven through the
same qsd77 CLI as the qsd77 edition.

To install use Calamares from the menu.

## AI in Utumno

Utumno has AI features built in, powered by Ollama, which is included and
enabled by default in this ISO. To use it you need to pull a model first. A
small, fast Qwen model is recommended to get started:

```
ollama pull qwen2.5:0.5b
```

Larger Qwen models (qwen2.5:1.5b, qwen2.5:3b, qwen2.5:7b, ...) will give
better answers if your hardware can handle them. Once a model is pulled,
the AI features in Utumno will be able to use it.

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

super + a -> Ollama assistant

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
