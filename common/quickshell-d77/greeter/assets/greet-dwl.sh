#!/bin/sh
# greet-dwl.sh
#
# Wrapper invoked by greetd to host the quickshell-d77 greeter under a
# minimal, disposable dwl instance. greetd runs this on the login VT
# before any user session exists; once the user logs in (or cancels),
# quickshell exits and dwl is told to quit so greetd can hand off the
# VT to the real session command the user picked.
#
# dwl has no IPC socket and its `-s` startup command does NOT terminate
# dwl when it exits -- see dwl.c's run(): the -s command is fork+execl'd
# directly with no setsid()/double-fork, so $PPID inside that shell is
# dwl's own PID. Sending it SIGTERM reproduces exactly what dwl's own
# quit keybind does (quit() -> wl_display_terminate(), also dwl's
# handler for SIGTERM/SIGINT), so `kill -TERM $PPID` after qs exits is
# the same as pressing Mod+Shift+Q.
#
# Deploy this file to e.g. /etc/greetd/quickshell-d77/greet-dwl.sh and
# point /etc/greetd/config.toml at it (see ../greetd-config.toml.example).
# Set GREETER_PATH to wherever this repo's greeter/ directory lives on
# this machine.

set -eu

GREETER_PATH="${GREETER_PATH:-/etc/greetd/quickshell-d77/greeter}"

if ! command -v qs >/dev/null 2>&1; then
    echo "Error: 'qs' (quickshell) was not found in PATH" >&2
    exit 1
fi
if ! command -v dwl >/dev/null 2>&1; then
    echo "Error: 'dwl' was not found in PATH" >&2
    exit 1
fi

export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export EGL_PLATFORM=gbm

exec dwl -s "qs -p $GREETER_PATH; kill -TERM \$PPID"
