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

## Powermenu

After install, to make powermenu work properly run:

```
sudo chmod u+s /usr/bin/poweroff
sudo chmod u+s /usr/bin/reboot
```

That way, even non privileged users can use powermenu.

## Keybinds

super + return -> terminal

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

## st directory

Inside this directory you have all the source code used to compile st.
All the dependencies are already installed in the iso, so, it is just a matter of adapt and compile to your needs.

Have fun!
