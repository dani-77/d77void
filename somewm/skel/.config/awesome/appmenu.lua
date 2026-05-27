local appmenu = {}

appmenu.Accessories = {
    { 'Bitwarden', '/opt/Bitwarden/bitwarden-app', '/usr/share/icons/hicolor/128x128/apps/bitwarden.png' },
    { 'Emacs', 'xterm -e emacs' },
    { 'Kvantum Manager', 'kvantummanager', '/usr/share/icons/hicolor/scalable/apps/kvantum.svg' },
    { 'Neovim', 'xterm -e nvim', '/usr/share/icons/hicolor/128x128/apps/nvim.png' },
    { 'Nextcloud Desktop', 'nextcloud --quit', '/usr/share/icons/hicolor/128x128/apps/Nextcloud.png' },
    { 'Nextcloud Desktop - use kwallet', '/usr/bin/nextcloud.kwallet', '/usr/share/icons/hicolor/128x128/apps/Nextcloud.png' },
    { 'OnlyKey App', '/opt/OnlyKey/nw', '/opt/OnlyKey/icon.png' },
    { 'Redshift', 'redshift-gtk', '/usr/share/icons/hicolor/scalable/apps/redshift.svg' },
    { 'Xarchiver', 'xarchiver', '/usr/share/icons/hicolor/16x16/apps/xarchiver.png' },
    { 'Yubico Authenticator', '"/opt/yubioath-flutter/authenticator"', '/opt/yubioath-flutter/linux_support/com.yubico.yubioath.png' },
}

appmenu.Games = {
    { 'Irony Curtain: From Matryoshka with Love', 'steam steam://rungameid/866190' },
    { 'Little Nightmares', 'steam steam://rungameid/424840' },
    { 'Steam', '/usr/bin/steam', '/usr/share/icons/hicolor/16x16/apps/steam.png' },
}

appmenu.Graphics = {
    { 'FontForge', 'fontforge', '/usr/share/icons/hicolor/128x128/apps/org.fontforge.FontForge.png' },
    { 'GNU Image Manipulation Program', 'gimp-3.0', '/usr/share/icons/hicolor/128x128/apps/gimp.png' },
}

appmenu.Internet = {
    { 'Brave Web Browser', '/usr/bin/brave-browser-stable' },
    { 'Geary', 'geary', '/usr/share/icons/hicolor/scalable/apps/org.gnome.Geary.svg' },
    { 'Mullvad Browser', '/usr/lib/mullvad-browser/start-mullvad-browser', '/usr/share/icons/hicolor/128x128/apps/mullvad-browser.png' },
    { 'Steam', '/usr/bin/steam', '/usr/share/icons/hicolor/16x16/apps/steam.png' },
    { 'Transmission (Qt)', 'transmission-qt', '/usr/share/icons/hicolor/scalable/apps/transmission-qt.svg' },
    { 'uGet', 'env GDK_BACKEND=x11 uget-gtk', '/usr/share/icons/hicolor/128x128/apps/uget-icon.png' },
}

appmenu.Office = {
    { 'AbiWord', 'abiword', '/usr/share/icons/hicolor/16x16/apps/abiword.png' },
    { 'Gnumeric', 'gnumeric --name org.gnumeric.gnumeric', '/usr/share/icons/hicolor/16x16/apps/org.gnumeric.gnumeric.png' },
    { 'Spice-Up', 'com.github.philip_scott.spice-up', '/usr/share/icons/hicolor/128x128/apps/com.github.philip_scott.spice-up.svg' },
    { 'Texmaker', 'texmaker' },
    { 'Zathura', 'zathura', '/usr/share/icons/hicolor/128x128/apps/org.pwmt.zathura.png' },
}

appmenu.MultiMedia = {
    { 'Echomixer', 'echomixer', '/usr/share/icons/hicolor/48x48/apps/echomixer.png' },
    { 'Envy24 Control', 'envy24control', '/usr/share/icons/hicolor/48x48/apps/envy24control.png' },
    { 'HDAJackRetask', 'hdajackretask' },
    { 'HDSPConf', 'hdspconf', '/usr/share/icons/hicolor/48x48/apps/hdspconf.png' },
    { 'HDSPMixer', 'hdspmixer', '/usr/share/icons/hicolor/48x48/apps/hdspmixer.png' },
    { 'Hwmixvolume', 'hwmixvolume', '/usr/share/icons/hicolor/128x128/apps/hwmixvolume.png' },
    { 'PulseAudio Volume Control', 'pavucontrol-qt' },
    { 'mpv Media Player', 'mpv --player-operation-mode=pseudo-gui --', '/usr/share/icons/hicolor/128x128/apps/mpv.png' },
    { 'ncspot', 'xterm -e ncspot', '/usr/share/icons/hicolor/scalable/apps/ncspot.svg' },
}

appmenu.Settings = {
    { 'Advanced Network Configuration', 'nm-connection-editor' },
    { 'Bluetooth Manager', 'blueman-manager', '/usr/share/icons/hicolor/128x128/apps/blueman.png' },
    { 'Desktop Preferences', 'pcmanfm --desktop-pref' },
    { 'GTK Settings', 'nwg-look' },
    { 'Kvantum Manager', 'kvantummanager', '/usr/share/icons/hicolor/scalable/apps/kvantum.svg' },
    { 'Manage Printing', 'xdg-open http://localhost:631/', '/usr/share/icons/hicolor/128x128/apps/cups.png' },
    { 'Print Settings', 'system-config-printer' },
    { 'PulseAudio Volume Control', 'pavucontrol-qt' },
    { 'Qt5 Settings', 'qt5ct' },
    { 'Qt6 Settings', 'qt6ct' },
}

appmenu.System = {
    { 'Htop', 'xterm -e htop', '/usr/share/icons/hicolor/scalable/apps/htop.svg' },
    { 'Manage Printing', 'xdg-open http://localhost:631/', '/usr/share/icons/hicolor/128x128/apps/cups.png' },
    { 'OctoXBPS', '/usr/bin/octoxbps', '/usr/share/icons/hicolor/48x48/apps/octopi.png' },
    { 'OctoXBPS Notifier', '/usr/bin/octoxbps-notifier', '/usr/share/icons/hicolor/48x48/apps/octopi.png' },
    { 'PCMan File Manager', 'pcmanfm' },
    { 'Print Settings', 'system-config-printer' },
    { 'UXTerm', 'uxterm' },
    { 'XTerm', 'xterm' },
    { 'conky', 'conky --daemonize --pause=1', '/usr/share/icons/hicolor/scalable/apps/conky-logomark-violet.svg' },
    { 'd77-welcome', 'xterm -e d77-welcome' },
    { 'gmrun', 'gmrun' },
    { 'joshuto', 'xterm -e joshuto' },
    { 'kitty', 'kitty', '/usr/share/icons/hicolor/256x256/apps/kitty.png' },
    { 'st', 'st' },
}

appmenu.Miscellaneous = {
    { 'Fresh-Editor', 'xterm -e fresh' },
    { 'Rofi', 'rofi -show', '/usr/share/icons/hicolor/scalable/apps/rofi.svg' },
    { 'Rofi Theme Selector', 'rofi-theme-selector', '/usr/share/icons/hicolor/scalable/apps/rofi.svg' },
}

appmenu.Appmenu = {
    { 'Accessories', appmenu.Accessories },
    { 'Games', appmenu.Games },
    { 'Graphics', appmenu.Graphics },
    { 'Internet', appmenu.Internet },
    { 'Office', appmenu.Office },
    { 'MultiMedia', appmenu.MultiMedia },
    { 'Settings', appmenu.Settings },
    { 'System', appmenu.System },
    { 'Miscellaneous', appmenu.Miscellaneous },
}

return appmenu