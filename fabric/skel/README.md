## Hello

Thank you for trying d77void Fabric edition.

To install use Calamares calling Install System from the menu.

## AI in fabric-d77

fabric-d77 has AI features built in, powered by Ollama, which is included and enabled by default in this ISO. To use it you need to pull a model first. A small, fast Qwen model is recommended to get started:

```
ollama pull qwen2.5:0.5b
```

Larger Qwen models (qwen2.5:1.5b, qwen2.5:3b, qwen2.5:7b, ...) will give better answers if your hardware can handle them. Once a model is pulled, the AI features in fabric-d77 will be able to use it.

## Keybinds

super + return -> terminal

super + d -> menu

super + i -> dashboard

super + shift + r -> gmrun

super + x -> powermenu

super + y -> wallpaper picker

super + t -> lock screen

super + shift + e -> logout

super + shift + c -> reload sway config

super + q -> close window

super + r -> resize window

## Sway tweaks

To alter the autostart programs, add/swap keybinds and keyboard layout configure ~/.config/sway/config ; the file is self explanatory and with several examples already configured.

Have fun!
