## Hello

Thank you for trying d77void qsd77 edition.

This ISO uses Hyprland together with Quickshell (my quickshell approach, qsd77).

To install use Calamares from the menu.

## AI in qsd77

qsd77 has AI features built in, powered by Ollama, which is included and enabled by default in this ISO. To use it you need to pull a model first. A small, fast Qwen model is recommended to get started:

```
ollama pull qwen2.5:0.5b
```

Larger Qwen models (qwen2.5:1.5b, qwen2.5:3b, qwen2.5:7b, ...) will give better answers if your hardware can handle them. Once a model is pulled, the AI features in qsd77 will be able to use it.

## Keybinds

super + return -> terminal

super + q -> close window

super + a -> applications menu

super + n -> menu2

super + i -> dashboard

super + j -> dwindle split

super + p -> print screen

super + r -> d77run

super + t -> lock screen

super + x -> session menu

super + y -> wallpaper picker

super + m -> logout

## qsd77 tweaks

To alter the autostart programs, add/swap keybinds and keyboard layout configure ~/.config/hypr/hyprland.lua ; the file is self explanatory and with several examples already configured.

Have fun!
