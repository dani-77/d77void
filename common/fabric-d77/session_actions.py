"""Agnostic session actions — fabric-d77.

Lock   : swaylock → hyprlock → loginctl lock-session
Logout : Hyprland → Sway → loginctl terminate-session → pkill
Reboot / Poweroff : systemctl (standard systemd)
"""

import os
import subprocess
import functools


def _has(cmd: str) -> bool:
    try:
        subprocess.run(["which", cmd], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False


@functools.lru_cache(maxsize=1)
def _locker() -> str:
    for locker in ("swaylock", "hyprlock"):
        if _has(locker):
            return locker
    return "loginctl lock-session"


def lock():
    os.system(f"{_locker()} &")


def logout():
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        os.system("hyprctl dispatch 'hl.dsp.exit()'")
    elif os.environ.get("SWAYSOCK"):
        os.system("swaymsg exit")
    else:
        session_id = os.environ.get("XDG_SESSION_ID", "")
        cmd = f"loginctl terminate-session {session_id}" if session_id else "pkill -KILL -u $USER"
        os.system(cmd)


def _power(action: str):
    """systemctl on systemd, loginctl on elogind (Void/runit, etc.)."""
    try:
        with open("/proc/1/comm") as f:
            init = f.read().strip()
    except Exception:
        init = ""
    cmd = f"systemctl {action}" if init == "systemd" else f"loginctl {action}"
    os.system(cmd)


def reboot():
    _power("reboot")


def poweroff():
    _power("poweroff")
