#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAM_DEST="/etc/pam.d/fabric-d77"

if [ ! -f "$PAM_DEST" ]; then
    if command -v pkexec >/dev/null 2>&1; then
        pkexec install -m644 "$SCRIPT_DIR/pam/fabric-d77" "$PAM_DEST" 2>/dev/null \
            || notify-send "fabric-d77" "Lock screen disabled: run 'sudo make install'" 2>/dev/null || true
    else
        sudo install -m644 "$SCRIPT_DIR/pam/fabric-d77" "$PAM_DEST" 2>/dev/null \
            || notify-send "fabric-d77" "Lock screen disabled: run 'sudo make install'" 2>/dev/null || true
    fi
fi

# pre-built venv from the ISO (fixed path, no network needed)
SYSTEM_VENV="/etc/xdg/fabric-d77/venv"
SYSTEM_SRC="/etc/xdg/fabric-d77"

# fallback: local venv (manual install outside the ISO)
USER_DIR="$HOME/.config/fabric-d77"
USER_VENV="$USER_DIR/venv"

if [ -d "$SYSTEM_VENV" ]; then
    source "$SYSTEM_VENV/bin/activate"
    exec python "$SYSTEM_SRC/main.py"
elif [ -d "$USER_VENV" ]; then
    source "$USER_VENV/bin/activate"
    exec python "$USER_DIR/main.py"
else
    LOG="$USER_DIR/setup.log"
    notify-send "fabric-d77" "Installing dependencies, please wait..." 2>/dev/null || true
    python3 -m venv "$USER_VENV" >"$LOG" 2>&1
    "$USER_VENV/bin/pip" install --upgrade pip >>"$LOG" 2>&1
    "$USER_VENV/bin/pip" install -r "$USER_DIR/requirements.txt" >>"$LOG" 2>&1
    notify-send "fabric-d77" "Setup complete." 2>/dev/null || true
    source "$USER_VENV/bin/activate"
    exec python "$USER_DIR/main.py"
fi
