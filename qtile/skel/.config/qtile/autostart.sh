#!/usr/bin/env bash
export QT_QPA_PLATFORM=wayland
gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark" &
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' &
dunst &
udiskie -a &
/usr/libexec/polkit-mate-authentication-agent-1 &
xcompmgr -c -f -n &
xautolock -time 5 -locker slock &
swayidle -w \
          timeout 300 'swaylock -f -c 000000' \
          timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
          before-sleep 'swaylock -f -c 000000' &
redshift -l 41.6:-8.62 -t 6500:4000 &
wlsunset -l 41.16 -L -8.62 -T 6500 -t 4000 &
synclient TapButton1=1 &
synclient TapButton2=3 &
synclient TapButton3=2 &
xrdb merge ~/.Xresources &
~/./.auto.sh &
