local appmenu = {}

appmenu.Accessories = {
    { 'Kvantum Manager', 'kvantummanager' },
    { 'Mousepad', 'mousepad' },
    { 'Xarchiver', 'xarchiver' },
}

appmenu.Internet = {
    { 'Brave Web Browser', '/usr/bin/brave-browser-stable' },
    { 'Geary', 'geary' },
    { 'Transmission (Qt)', 'transmission-qt' },
    { 'uGet', 'env GDK_BACKEND=x11 uget-gtk' },
}

appmenu.Office = {
    { 'Zathura', 'zathura' },
}

appmenu.MultiMedia = {
    { 'Echomixer', 'echomixer' },
    { 'Envy24 Control', 'envy24control' },
    { 'HDAJackRetask', 'hdajackretask' },
    { 'HDSPConf', 'hdspconf' },
    { 'HDSPMixer', 'hdspmixer' },
    { 'Hwmixvolume', 'hwmixvolume' },
    { 'mpv Media Player', 'mpv --player-operation-mode=pseudo-gui --' },
}

appmenu.Settings = {
    { 'Desktop Preferences', 'pcmanfm --desktop-pref' },
    { 'GTK Settings', 'nwg-look' },
    { 'Kvantum Manager', 'kvantummanager' },
    { 'Manage Printing', 'xdg-open http://localhost:631/' },
    { 'Print Settings', 'system-config-printer' },
    { 'Qt5 Settings', 'qt5ct' },
    { 'Qt6 Settings', 'qt6ct' },
}

appmenu.System = {
    { 'Alacritty', 'alacritty' },
    { 'Htop', 'xterm -e htop' },
    { 'Install System', 'sudo -E calamares' },
    { 'Manage Printing', 'xdg-open http://localhost:631/' },
    { 'OctoXBPS', '/usr/bin/octoxbps' },
    { 'OctoXBPS Notifier', '/usr/bin/octoxbps-notifier' },
    { 'PCMan File Manager', 'pcmanfm' },
    { 'Print Settings', 'system-config-printer' },
    { 'd77-welcome', 'xterm -e d77-welcome' },
    { 'd77run', 'd77run' },
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