

Hello Thank you for trying d77void.

To run the installer just open a terminal and type:

```
sudo d77void-installer
```

Note: To maintain the configuration of the live iso, during install, choose local instead of network install.

During install, add your user to the storage group. That way udiskie will automount disks.

# NEWS

- Brave browser is now the default browser;

- Hyprlock configured;

- new d77-welcome script avilable and corrected;

- some minor changes in keybinds;

- to use calamares just call rofi and select installer


## 1st run:

After install, run the script d77-welcome:

```
d77-welcome
```

That way the hyprland repo will be added to /etc/xbps.d

# Keybinds

super + return -> terminal

super + q -> close window

super + shift + q -> logout

super + d -> menu

super + w -> web browser

super + f -> file manager

super + b -> swap background

super + x -> powermenu

super + t -> lock screen

Have fun!
