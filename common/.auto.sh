#!/bin/sh
exec xdg-user-dirs-update &
exec xdg-user-dirs-gtk-update &
# Live session only: bring the installer straight up. `sudo -E` (the live
# user has NOPASSWD) reaches the session where `pkexec calamares` did not --
# no polkit agent is up yet at .auto.sh time. Calamares xbps-removes itself
# at the end of an install (packages.conf), so `command -v` fails on the
# installed system and this is a no-op there.
command -v calamares >/dev/null 2>&1 && exec sudo -E calamares &
exec d77-welcome --open
