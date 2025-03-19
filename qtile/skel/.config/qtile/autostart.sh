#!/usr/bin/env bash
gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark" &
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' &
wlsunset -t 3500 -T 5700 -l 41.6 -L -8.62 -g 0.8 &
dunst &
udiskie -a &
picom &
