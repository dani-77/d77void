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

super + o -> gmrun

super + a -> rofi

super + x -> powermenu

## Labwc tweaks

To alter the autostart programs, add/swap keybinds, change keyboard layout and menu items configure the files inside ~/.config/labwc/ ; the files are self explanatory and with several examples already configured.

Have fun!
