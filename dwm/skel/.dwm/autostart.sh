#!/bin/bash

# audio
exec pipewire &

# notifications
exec dunst &

# polkit authentication agent
exec /usr/libexec/polkit-mate-authentication-agent-1 &

# transparency
exec xcompmgr -c -f -n &

# nightshift for Oporto, Portugal location
exec redshift -l 41.6:-8.62 & 

# keybind mapper
exec sxhkd -c ~/.config/sxhkd/sxhkdrc &

# automount disks
exec udiskie -a &

# wallpaper
exec feh --bg-fill ~/Wallpaper/dwm_d77.png &
exec xrdb merge ~/.Xresources &

# screenlocker
exec xautolock -time 10 -locker slock &

# bar
exec slstatus &

# touchpad
exec synclient TapButton1=1 &
exec synclient TapButton2=3 &
exec synclient TapButton3=2 &

# README.md
exec ~/./.auto.sh &
