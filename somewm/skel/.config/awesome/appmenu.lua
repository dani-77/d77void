local appmenu = {}

appmenu.Accessories = {
    { 'Kvantum Manager', 'kvantummanager', '/usr/share/icons/hicolor/scalable/apps/kvantum.svg' },
    { 'Mousepad', 'mousepad', '/usr/share/icons/hicolor/96x96/apps/org.xfce.mousepad.png' },
    { 'Xarchiver', 'xarchiver', '/usr/share/icons/hicolor/scalable/apps/xarchiver.svg' },
}

appmenu.Internet = {
    { 'Brave Web Browser', '/usr/bin/brave-browser-stable' },
    { 'Geary', 'geary', '/usr/share/icons/hicolor/scalable/apps/org.gnome.Geary.svg' },
    { 'Transmission (Qt)', 'transmission-qt' },
    { 'uGet', 'env GDK_BACKEND=x11 uget-gtk', '/usr/share/icons/hicolor/96x96/apps/uget-icon.png' },
}

appmenu.Office = {
    { 'Zathura', 'zathura', '/usr/share/icons/hicolor/scalable/apps/org.pwmt.zathura.svg' },
}

appmenu.MultiMedia = {
    { 'Echomixer', 'echomixer', '/usr/share/icons/hicolor/48x48/apps/echomixer.png' },
    { 'Envy24 Control', 'envy24control', '/usr/share/icons/hicolor/48x48/apps/envy24control.png' },
    { 'HDAJackRetask', 'hdajackretask' },
    { 'HDSPConf', 'hdspconf', '/usr/share/icons/hicolor/48x48/apps/hdspconf.png' },
    { 'HDSPMixer', 'hdspmixer', '/usr/share/icons/hicolor/48x48/apps/hdspmixer.png' },
    { 'Hwmixvolume', 'hwmixvolume', '/usr/share/icons/hicolor/128x128/apps/hwmixvolume.png' },
    { 'mpv Media Player', 'mpv --player-operation-mode=pseudo-gui --', '/usr/share/icons/hicolor/scalable/apps/mpv.svg' },
}

appmenu.Settings = {
    { 'Desktop Preferences', 'pcmanfm --desktop-pref' },
    { 'GTK Settings', 'nwg-look' },
    { 'Kvantum Manager', 'kvantummanager', '/usr/share/icons/hicolor/scalable/apps/kvantum.svg' },
    { 'Manage Printing', 'xdg-open http://localhost:631/', '/usr/share/icons/hicolor/32x32/apps/cups.png' },
    { 'Print Settings', 'system-config-printer' },
    { 'Qt5 Settings', 'qt5ct' },
    { 'Qt6 Settings', 'qt6ct' },
}

appmenu.System = {
    { 'Alacritty', 'alacritty', '/usr/share/icons/hicolor/scalable/apps/Alacritty.svg' },
    { 'Htop', 'xterm -e htop', '/usr/share/icons/hicolor/scalable/apps/htop.svg' },
    { 'Install System', 'sudo -E calamares', '/usr/share/icons/hicolor/scalable/apps/calamares.svg' },
    { 'Manage Printing', 'xdg-open http://localhost:631/', '/usr/share/icons/hicolor/32x32/apps/cups.png' },
    { 'OctoXBPS', '/usr/bin/octoxbps', '/usr/share/icons/hicolor/48x48/apps/octopi.png' },
    { 'OctoXBPS Notifier', '/usr/bin/octoxbps-notifier', '/usr/share/icons/hicolor/48x48/apps/octopi.png' },
    { 'PCMan File Manager', 'pcmanfm' },
    { 'Print Settings', 'system-config-printer' },
    { 'd77-welcome', 'xterm -e d77-welcome' },
    { 'gmrun', 'gmrun' },
    { 'ranger', 'xterm -e ranger' },
}

appmenu.Appmenu = {
    { 'Accessories', appmenu.Accessories },
    { 'Internet', appmenu.Internet },
    { 'Office', appmenu.Office },
    { 'MultiMedia', appmenu.MultiMedia },
    { 'Settings', appmenu.Settings },
    { 'System', appmenu.System },
}

return appmenu