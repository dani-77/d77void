Hello
Thank you for trying d77void.

To run the installer just open a terminal and type:

```
sudo void-installer
```

Note: 
To maintain the configuration of the live iso, during install, choose local instead of network install.

During install, add your user to the storage group. That way udiskie will automount disks.


# After install

## 1st run

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

## Labwc

To alter the autostart programs, add/swap keybinds, change keyboard layout and menu items configure the files inside ~/.config/labwc ; the files are self explanatory and with several examples already configured.

## Waybar and Sfwbar

In ~/.config/waybar there are several styles and configs; adapt to your liking and need. wittr.sh has to be modified to suit your CITY.

In ~/.config/sfwbar there are several configs, being the default w10.config with some minor changes.

Have fun!
