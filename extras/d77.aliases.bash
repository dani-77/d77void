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
		alias pkgsig='xbps-rindex --sign-pkg --privkey privkey.pem hostdir/binpkgs/*.xbps'

		alias srcbuild='./xbps-src pkg'
	fi
}

_set_pkg_aliases
