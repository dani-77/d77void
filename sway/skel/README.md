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

Have fun!
