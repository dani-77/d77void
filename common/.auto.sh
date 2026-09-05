#!/bin/sh
exec xdg-user-dirs-update &
exec xdg-user-dirs-gtk-update &
# Live session only: Calamares xbps-removes itself at the end of an install
# (packages.conf), so on the installed system `command -v` fails and this is
# a no-op. In the live session it brings the installer straight up.
command -v calamares >/dev/null 2>&1 && pkexec calamares &
exec d77-welcome --open
