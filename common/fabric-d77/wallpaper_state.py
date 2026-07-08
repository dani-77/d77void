import os

# Where the last wallpaper chosen in the picker (wallpaper_selector.py) is
# persisted across logout/reboot. Read at Hyprland startup by
# apply-saved-wallpaper.sh before awww-daemon applies anything.
#
# Own namespace (~/.cache/fabric-d77/...), separate from quickshell-d77
# (~/.cache/quickshell/...) — they are independent shells and must not
# overwrite each other's state.
STATE_DIR = os.path.expanduser("~/.cache/fabric-d77/wallpaper")
STATE_FILE = os.path.join(STATE_DIR, "current")


def read_current() -> str | None:
    """Returns the saved path, or None if none exists or the file is gone."""
    try:
        with open(STATE_FILE, "r") as f:
            path = f.read().strip()
    except FileNotFoundError:
        return None
    return path if path and os.path.isfile(path) else None


def write_current(path: str) -> None:
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(STATE_FILE, "w") as f:
        f.write(path)


def clear_current() -> None:
    try:
        os.remove(STATE_FILE)
    except FileNotFoundError:
        pass
