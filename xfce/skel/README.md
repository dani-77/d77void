Hello
Thank you for trying d77void.

To run the installer just open a terminal and type:

```
sudo d77void-installer
```

Note: 
To maintain the configuration of the live iso, during install, choose local instead of network install.

During install, add your user to the storage group. That way udiskie will automount disks.

To install with Calamares:

```
su

calamares
```

# 1st run:

Because XFCE has a way to run in wayland, I needed to install labwc as WM for wayland;

The WM is configured but is not fully functional, so labwc and XFCE wayland should be avoided.

In order to do it, because in SDDM the default session is labwc (I couldn´t swap it), you shoud swap session to XFCE, not the wayland one.

Have fun!
