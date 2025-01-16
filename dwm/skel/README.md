Hello
Thank you for trying d77Void.

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

alt + shift + return -> terminal

alt + w -> firefox

alt + p -> scrot

alt + l -> slock

alt + x -> powermenu

super + m -> geary

super + f -> pcmanfm

super + d -> rofi

## Suckless directory

Inside this directory you have all the source code used to compile the programs from suckless, from the window manager (dwm) to a web surfer that is not installed in the iso (surf).
All the dependencies are already installed in the iso, so, it is just a matter of compile and adapt to your needs.

Have fun!
