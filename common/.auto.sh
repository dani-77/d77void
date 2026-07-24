#!/bin/sh
exec xdg-user-dirs-update &
exec xdg-user-dirs-gtk-update &
exec d77-welcome --open
