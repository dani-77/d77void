#!/bin/bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Allow users to override command-line options
if [[ -f "$XDG_CONFIG_HOME/freetube-flags.conf" ]]; then
   FREETUBE_FLAGS="$(grep -v '^#' "$XDG_CONFIG_HOME/freetube-flags.conf")"
fi

# Launch
export ELECTRON_IS_DEV=0
exec /opt/FreeTube/freetube $FREETUBE_FLAGS "$@"
