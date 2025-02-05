Hello
Thank you for trying d77void.

To run the installer just open a terminal and type:

```
sudo void-installer
```

Note: 
To mantain the configuration of the live iso, during install, choose local instead of network install.

During install, add your user to the storage group. That way udiskie will automount disks.


# 1st run:

## Keybinds

super + return -> terminal

super + p -> rofi

super + o -> gmrun

super + x -> powermenu

## Labwc tweaks

To alter the autostart programs, add/swap keybinds, change keyboard layout and menu items configure the files inside ~/.config/labwc/ ; the files are self explanatory and with several examples already configured.

## st directory

Inside this directory you have all the source code used to compile st.
All the dependencies are already installed in the iso, so, it is just a matter of adapt and compile to your needs.

Have fun!
