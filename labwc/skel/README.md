Hello
Thank you for trying d77void.

To run the installer just open a terminal and type:

```
sudo d77void-installer
```

Note: 
To maintain the configuration of the live iso, during install, choose local instead of network install.

During install, add your user to the storage group. That way udiskie will automount disks.

# NEWS

Now Calamares installer is available making the install process even simpler.

I would like to thank Calamares team, Kevin Figueroa (Cereus Linux) and johna1 (F-Void Linux) for all the work done and guidance.

I would like to express my gratitude and say a big thank you to Rúben Gomez (Youtube channel Ruben_&_Linux_:~) for all the encouragement.

To install using Calamares:

```
su

calamares
```

## Keybinds

super + return -> terminal

super + a -> rofi

super + b -> swap wallpaper

super + f -> filemanager

super + m -> mail

super + p -> printscreen

super + r -> gmrun

super + t -> lock screen

super + w -> firefox

super + x -> powermenu

## Labwc

To alter the autostart programs, add/swap keybinds, change keyboard layout and menu items configure the files inside ~/.config/labwc ; the files are self explanatory and with several examples already configured.

## Waybar and Sfwbar

In ~/.config/waybar there are several styles and configs; adapt to your liking and need. wittr.sh has to be modified to suit your CITY.

In ~/.config/sfwbar there are several configs, being the default w10.config with some minor changes.

Have fun!
