Hello
Thank you for trying d77void.

To run the installer just open a terminal and type:

```
sudo void-installer
```

Note: 
To maintain the configuration of the live iso, during install, choose local instead of network install.

During install, add your user to the storage group. That way udiskie will automount disks.


# 1st run:

After install, run the script 1strun:

```
sudo ./1strun
```

That way, a new sddm greeter will be available.

## Keybinds

super + return -> terminal

super + b -> swap wallpaper

super + d -> wmenu

super + p -> rofi

super + o -> gmrun

super + x -> powermenu

super + shift + e -> logout

super + shift + c -> reload sway config

super + shift + q -> close window

super + r -> resize window

## Sway tweaks

To alter the autostart programs, add/swap keybinds and keyboard layout configure ~/.config/sway/config ; the file is self explanatory and with several examples already configured.

Have fun!
