#!/usr/bin/env bash
gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark" &
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' &
wlsunset -t 3500 -T 5700 -l 41.6 -L -8.62 -g 0.8 &
synclient TapButton1=1 &
synclient TapButton2=3 &
synclient TapButton3=2 &
xcompmgr -c -f -n &
redshift -l 41.6:-8.62 &
