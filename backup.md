PROGNAME=$(basename "$0")
ARCH=$(uname -m)
IMAGES="base dwm fluxbox hyprland labwc openbox sway"
TRIPLET=
REPO=
DATE=$(date -u +%Y%m%d)

usage() {
	cat <<-EOH
	Usage: $PROGNAME [options ...] [-- mklive options ...]

	Wrapper script around mklive.sh for several standard flavors of live images.
	Adds d77void-installer and other helpful utilities to the generated images.
        
	adaptation of mkiso.sh by Daniel Azevedo (dani-77) 

	OPTIONS
	 -a <arch>     Set architecture (or platform) in the image
	 -b <variant>  One of base, dwm, fluxbox, hyprland, labwc, openbox or sway. 
               May be specified multiple times to build multiple variants.
	 -d <date>     Override the datestamp on the generated image (YYYYMMDD format)
	 -t <arch-date-variant>
	               Equivalent to setting -a, -b, and -d
	 -r <repo>     Use this XBPS repository. May be specified multiple times
	 -h            Show this help and exit
	 -V            Show version and exit

	Other options can be passed directly to mklive.sh by specifying them after the --.
	See mklive.sh -h for more details.
	EOH
}





include_common() {
	mkdir -p "$INCLUDEDIR"/etc
	mkdir -p "$INCLUDEDIR"/etc/default
	mkdir -p "$INCLUDEDIR"/etc/skel
	mkdir -p "$INCLUDEDIR"/usr/bin
	mkdir -p "$INCLUDEDIR"/usr/share/polkit-1/rules.d
	mkdir -p "$INCLUDEDIR"/usr/share/void-artwork
	cp -r $variant/calamares "$INCLUDEDIR"/etc/
	cp -r $variant/skel "$INCLUDEDIR"/etc/skel/
	cp $variant/50-udisks.rules "$INCLUDEDIR"/usr/share/polkit-1/rules.d/
	cp $variant/splash.png "$INCLUDEDIR"/usr/share/void-artwork/
	cp $variant/grub "$INCLUDEDIR"/etc/default/
}

include_way() {
	mkdir -p "$INCLUDEDIR"/usr/share/sddm/faces
	mkdir -p "$INCLUDEDIR"/usr/share/sddm/themes
	cp $variant/sddm.conf "$INCLUDEDIR"/etc/
	cp $variant/wswap-way "$INCLUDEDIR"/usr/bin/
	cp $variant/rofi-power-menu "$INCLUDEDIR"/usr/bin/
	cp -r $variant/slice "$INCLUDEDIR"/usr/share/sddm/themes/
	cp $variant/anon.face.icon "$INCLUDEDIR"/usr/share/sddm/faces/
}	

include_x11() {
	mkdir -p "$INCLUDEDIR"/usr/share/sddm/faces
	mkdir -p "$INCLUDEDIR"/usr/share/sddm/themes
	cp $variant/sddm.conf "$INCLUDEDIR"/etc/
	cp $variant/rofi-power-menu "$INCLUDEDIR"/usr/bin/
	cp -r $variant/slice "$INCLUDEDIR"/usr/share/sddm/themes/
	cp $variant/anon.face.icon "$INCLUDEDIR"/usr/share/sddm/faces/
	cp $variant/wswap-X "$INCLUDEDIR"/usr/bin/
}	

include_dwm() {
	mkdir -p "$INCLUDEDIR"/etc/default
	mkdir -p "$INCLUDEDIR"/etc/skel
	mkdir -p "$INCLUDEDIR"/usr/bin
	mkdir -p "$INCLUDEDIR"/usr/share/polkit-1/rules.d
	mkdir -p "$INCLUDEDIR"/usr/share/void-artwork
	cp -r $variant/calamares "$INCLUDEDIR"/etc/calamares
	cp -r $variant/skel "$INCLUDEDIR"/etc/
	cp $variant/50-udisks.rules "$INCLUDEDIR"/usr/share/polkit-1/rules.d/
	cp $variant/splash.png "$INCLUDEDIR"/usr/share/void-artwork/
	mkdir -p "$INCLUDEDIR"/usr/share/terminfo/s
	mkdir -p "$INCLUDEDIR"/usr/share/slim/themes
	cp $variant/slim.conf "$INCLUDEDIR"/etc/
	cp $variant/dwm "$INCLUDEDIR"/usr/bin/
	cp $variant/slock "$INCLUDEDIR"/usr/bin/
	cp $variant/slstatus "$INCLUDEDIR"/usr/bin/
	cp $variant/st "$INCLUDEDIR"/usr/bin/
	cp $variant/st-* "$INCLUDEDIR"/usr/share/terminfo/s/
	cp $variant/wswap-X "$INCLUDEDIR"/usr/bin/
	cp $variant/power_menu "$INCLUDEDIR"/usr/bin/
	cp -r $variant/greeny_dark "$INCLUDEDIR"/usr/share/slim/themes/
}





            CALAMARES="calamares grub rsync"
	    COMMON=
	    X11=
	    WAY=





	dwm)
	    DWM=yes
            PKGS="$PKGS $XORG_PKGS base-devel fontconfig-devel freetype-devel gcr-devel gcr4-devel glibc-devel gtk+3-devel harfbuzz-devel imlib2-devel libX11-devel libXft-devel libXinerama-devel webkit2gtk-devel abiword acpi apulse alsa-plugins-pulseaudio alsa-tools alsa-utils arc-theme bash-completion bc ca-certificates cmus cups cups-browsed curl dmenu dunst elogind epson-inkjet-printer-escpr ethtool feh firefox font-awesome font-awesome5 font-awesome6 font-hack-ttf geary gettext git github-cli gmrun gnumeric htop inxi lxappearance mousepad mpv nano ncspot NetworkManager nerd-fonts-symbols-ttf neofetch nextcloud-client octoxbps papirus-icon-theme pcmanfm polkit pcsc-ccid pcsc-tools pcsclite ranger redshift rofi scrot slim slock smartmontools sxhkd tlp tlp-rdw transmission-gtk transset udiskie ueberzug ufw uget unzip usbutils util-linux vim void-repo-multilib void-repo-multilib-nonfree void-repo-nonfree wget xautolock xcompmgr xdg-user-dirs xdg-user-dirs-gtk xdg-utils xf86-input-synaptics xarchiver xcalc xinit xorg xorg-server xpdf xterm yt-dlp zathura zathura-pdf-poppler"
            SERVICES="$SERVICES dbus elogind slim NetworkManager polkitd"
        ;;
	fluxbox)
	    COMMON=yes
	    X11=yes
            PKGS="$PKGS $XORG_PKGS $CALAMARES abiword acpi apulse alsa-plugins-pulseaudio alsa-tools alsa-utils arc-theme bash-completion bc ca-certificates cbatticon cmus conky cups cups-browsed curl dunst elogind epson-inkjet-printer-escpr ethtool feh firefox fluxbox font-hack-ttf geary gettext git github-cli gmrun gnumeric htop inxi jgmenu jq lxappearance mousepad mpv nano ncspot NetworkManager network-manager-applet nerd-fonts-symbols-ttf neofetch nextcloud-client octoxbps papirus-icon-theme pass pcmanfm polkit pcsc-ccid pcsc-tools pcsclite ranger redshift redshift-gtk rofi scrot slim slock smartmontools system-config-printer tlp tlp-rdw transmission-gtk transset udiskie ueberzug ufw uget unzip usbutils util-linux vim void-repo-multilib void-repo-multilib-nonfree void-repo-nonfree volumeicon wget xautolock xcompmgr xdg-user-dirs xdg-user-dirs-gtk xdg-utils xf86-input-synaptics xarchiver xcalc xinit xorg xorg-server xpdf xterm yt-dlp zathura zathura-pdf-poppler"
            SERVICES="$SERVICES dbus elogind sddm NetworkManager polkitd"
        ;;
	hyprland)
	    COMMON=yes
	    WAY=yes
            PKGS="$PKGS $XORG_PKGS $WAYLAND_PKGS $CALAMARES acpi apulse alsa-plugins-pulseaudio alsa-tools alsa-utils arc-theme bash-completion bc brightnessctl ca-certificates cups cups-browsed curl elogind epson-inkjet-printer-escpr ethtool feh firefox font-awesome6 font-hack-ttf geary gettext git github-cli gmrun grim htop hyprland ImageMagick inxi kitty lxappearance mousepad mpv nano ncspot NetworkManager network-manager-applet nerd-fonts-symbols-ttf neofetch nextcloud-client octoxbps papirus-icon-theme pavucontrol pcmanfm polkit qt6-wayland ranger rofi sddm smartmontools swaybg swayidle swayimg swaylock SwayNotificationCenter system-config-printer tlp tlp-rdw transmission-gtk udiskie ueberzug ufw uget unzip usbutils util-linux vim void-repo-multilib void-repo-multilib-nonfree void-repo-nonfree wayland-devel wayland-protocols Waybar wget wlsunset wmenu xdg-user-dirs xdg-user-dirs-gtk xdg-utils xf86-input-synaptics xarchiver xcalc xorg-server-xwayland xpdf xterm yt-dlp zathura zathura-pdf-poppler"
            SERVICES="$SERVICES dbus elogind sddm NetworkManager polkitd"
        ;;
	labwc)
	    COMMON=yes
	    WAY=yes
            PKGS="$PKGS $XORG_PKGS $WAYLAND_PKGS $CALAMARES abiword acpi apulse alsa-plugins-pulseaudio alsa-tools alsa-utils arc-theme bash-completion bc brightnessctl ca-certificates cups cups-browsed curl elogind epson-inkjet-printer-escpr ethtool feh firefox font-awesome6 font-hack-ttf geary gettext git github-cli gmrun gnumeric grim htop ImageMagick inxi kitty labwc labwc-menu-generator labwc-tweaks-qt lxappearance mousepad mpv nano ncspot NetworkManager network-manager-applet nerd-fonts-symbols-ttf neofetch nextcloud-client octoxbps papirus-icon-theme pcmanfm polkit pcsc-ccid pcsc-tools pcsclite ranger rofi sddm sfwbar smartmontools swaybg swayidle swayimg swaylock SwayNotificationCenter system-config-printer tlp tlp-rdw transmission-gtk udiskie ueberzug ufw uget unzip usbutils util-linux vim void-repo-multilib void-repo-multilib-nonfree void-repo-nonfree Waybar wget wlsunset xdg-user-dirs xdg-user-dirs-gtk xdg-utils xf86-input-synaptics xarchiver xcalc xpdf xterm yt-dlp zathura zathura-pdf-poppler"
            SERVICES="$SERVICES dbus elogind sddm NetworkManager polkitd"
        ;;
	openbox)
	    COMMON=yes
	    X11=yes
            PKGS="$PKGS $XORG_PKGS $CALAMARES abiword acpi apulse alsa-plugins-pulseaudio alsa-tools alsa-utils arc-theme bash-completion bc ca-certificates cbatticon cmus conky cups cups-browsed curl dunst elogind epson-inkjet-printer-escpr ethtool feh firefox font-hack-ttf geary gettext git github-cli gmrun gnumeric htop inxi jgmenu jq lxappearance lxappearance-obconf menumaker mousepad mpv nano ncspot NetworkManager network-manager-applet nerd-fonts-symbols-ttf neofetch nextcloud-client obconf octoxbps openbox papirus-icon-theme pcmanfm polkit pcsc-ccid pcsc-tools pcsclite ranger redshift redshift-gtk rofi scrot slim slock smartmontools sxhkd system-config-printer tint2 tint2conf tlp tlp-rdw transmission-gtk transset udiskie ueberzug ufw uget unzip usbutils util-linux vim void-repo-multilib void-repo-multilib-nonfree void-repo-nonfree volumeicon wget xautolock xcompmgr xdg-user-dirs xdg-user-dirs-gtk xdg-utils xf86-input-synaptics xarchiver xcalc xinit xorg xorg-server xpdf xterm yt-dlp zathura zathura-pdf-poppler"
            SERVICES="$SERVICES dbus elogind sddm NetworkManager polkitd"
        ;;        
	sway)
	    COMMON=yes
	    WAY=yes
            PKGS="$PKGS $XORG_PKGS $WAYLAND_PKGS $CALAMARES abiword acpi apulse alsa-plugins-pulseaudio alsa-tools alsa-utils arc-theme bash-completion bc brightnessctl ca-certificates cups cups-browsed curl elogind epson-inkjet-printer-escpr ethtool feh firefox font-awesome6 font-hack-ttf geary gettext git github-cli gmrun gnumeric grim htop ImageMagick inxi kitty lxappearance mousepad mpv nano ncspot NetworkManager network-manager-applet nerd-fonts-symbols-ttf neofetch nextcloud-client octoxbps papirus-icon-theme pavucontrol pcmanfm polkit pcsc-ccid pcsc-tools pcsclite ranger rofi sddm smartmontools sway swaybg swayidle swayimg swaylock SwayNotificationCenter system-config-printer tlp tlp-rdw transmission-gtk udiskie ueberzug ufw uget unzip usbutils util-linux vim void-repo-multilib void-repo-multilib-nonfree void-repo-nonfree Waybar wget wlsunset wmenu xdg-user-dirs xdg-user-dirs-gtk xdg-utils xf86-input-synaptics xarchiver xcalc xpdf xterm yt-dlp zathura zathura-pdf-poppler"
            SERVICES="$SERVICES dbus elogind sddm NetworkManager polkitd"
        ;;





    if [ "$COMMON" = yes ]; then
        include_common
    fi

    if [ "$DWM" = yes ]; then
        include_dwm
    fi

    if [ "$X11" = yes ]; then
        include_x11
    fi

    if [ "$WAY" = yes ]; then
        include_way
    fi
