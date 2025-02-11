# notifications
exec dunst &
# transparency
exec xcompmgr -c -f -n &
# nightshift for Oporto, Portugal location
#exec redshift -l 41.6:-8.62 & 
# keybind mapper
exec sxhkd -c ~/.config/sxhkd/sxhkdrc &
# automount disks
exec udiskie -a &
# wallpaper
exec feh --bg-fill --randomize ~/Wallpaper/ &
#exec xrdb merge ~/.Xresources &
# screenlocker
exec xautolock -time 10 -locker slock &
# bar
exec slstatus &
# keymap
#exec setxkbmap de deadtilde &
# touchpad
exec synclient TapButton1=1 &
exec synclient TapButton2=3 &
exec synclient TapButton3=2 &
exec dwm
