#!/usr/bin/env bash

# venv pré-construído na ISO (path fixo, sem necessidade de rede)
SYSTEM_VENV="/etc/xdg/fabric-d77/venv"
SYSTEM_SRC="/etc/xdg/fabric-d77"

# fallback: venv local (instalação manual fora da ISO)
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
    notify-send "fabric-d77" "A instalar dependências, aguarda..." 2>/dev/null || true
    python3 -m venv "$USER_VENV" >"$LOG" 2>&1
    "$USER_VENV/bin/pip" install --upgrade pip >>"$LOG" 2>&1
    "$USER_VENV/bin/pip" install -r "$USER_DIR/requirements.txt" >>"$LOG" 2>&1
    notify-send "fabric-d77" "Setup concluído." 2>/dev/null || true
    source "$USER_VENV/bin/activate"
    exec python "$USER_DIR/main.py"
fi
