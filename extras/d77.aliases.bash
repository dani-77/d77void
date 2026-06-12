# shellcheck shell=bash
#
# -binaryanomaly

cite 'about-alias'
about-alias 'XBPS and xbps-src aliases for d77void, Void and Void derivative distros.'

# set xbps aliases
function _set_pkg_aliases() {
	if _command_exists xbps-install; then
		alias pkgsearch='xbps-query -Rs'
		alias pkginst='sudo xbps-install -S'
		alias pkgupg='sudo xbps-install -Syu'
		alias pkgrm='sudo xbps-remove -R'
		alias pkgsig='xbps-rindex --sign-pkg --privkey privkey.pem hostdir/binpkgs/d77/*.xbps'
		alias srcbuild='./xbps-src pkg'
		alias muslsrcbuild='./xbps-src pkg -A x86_64-musl'

		alias klist='vkpurge list'
		alias krem='sudo vkpurge rm'

		alias muslisobuild='sudo ./musl-d77 -a x86_64-musl -r /home/dani77/d77void-pkgs/hostdir/binpkgs/musld77/'
		alias isobuild='sudo ./d77 -r /home/dani77/d77void-pkgs/hostdir/binpkgs/d77/'
		alias hyprbuild='sudo ./d77 -r /home/dani77/d77void-pkgs/hostdir/binpkgs/d77/ -r https://raw.githubusercontent.com/sofijacom/hyprland-void/repository-x86_64-glibc'
		alias sbuild='sudo ./d77 -r /home/dani77/d77void-pkgs/hostdir/binpkgs/d77/ -r https://raw.githubusercontent.com/Event-Horizon-VL/blackhole-vl/repository-x86_64'
		alias cosmicbuild='sudo ./d77 -r /home/dani77/d77void-pkgs/hostdir/binpkgs/ -r /home/dani77/d77void-pkgs/hostdir/binpkgs/d77/ -r https://bellawagner.de/repo/x86_64 -b cosmic -- -T d77void'
		alias nisobuild='sudo ./d77nc -r /home/dani77/d77void-pkgs/hostdir/binpkgs/d77/'
		alias nhyprbuild='sudo ./d77nc -r /home/dani77/d77void-pkgs/hostdir/binpkgs/d77/ -r https://raw.githubusercontent.com/sofijacom/hyprland-void/repository-x86_64-glibc'
		alias nsbuild='sudo ./d77nc -r /home/dani77/d77void-pkgs/hostdir/binpkgs/d77/ -r https://raw.githubusercontent.com/Event-Horizon-VL/blackhole-vl/repository-x86_64'
		alias ncosmicbuild='sudo ./d77nc -r /home/dani77/d77void-pkgs/hostdir/binpkgs/ -r /home/dani77/d77void-pkgs/hostdir/binpkgs/d77/ -r https://bellawagner.de/repo/x86_64 -b cosmic -- -T d77void'
	fi
}

_set_pkg_aliases
