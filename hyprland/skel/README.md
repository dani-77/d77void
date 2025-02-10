

Hello Thank you for trying d77void.

To run the installer just open a terminal and type:

```
sudo void-installer
```

Note: To maintain the configuration of the live iso, during install, choose local instead of network install.

During install, add your user to the storage group. That way udiskie will automount disks.
1st run:

After install, run the script 1strun:

```
sudo ./1strun
```

That way, a new sddm greeter will be available and hopefully the hyprland repo added to /etc/xbps.d
Keybinds

super + return -> terminal

super + c -> close window

super + q -> logout

super + d -> menu

super + w -> web browser

super + f -> file manager

super + b -> swap background

super + x -> powermenu

Have fun!
