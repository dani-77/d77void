"""
terminal_launcher.py

Resolves which terminal to use (TERMINAL env -> xdg-terminal-exec -> fallback
list) and launches DesktopApp commands respecting Terminal=true in .desktop
files, instead of relying on Fabric's default app.launch() behaviour.
"""

import configparser
import os
import re
import shlex
import shutil
import subprocess

# Standard XDG directories where .desktop files live
XDG_APP_DIRS = [
    os.path.expanduser("~/.local/share/applications"),
    "/usr/local/share/applications",
    "/usr/share/applications",
]

_terminal_flag_cache: dict[str, bool] = {}

FALLBACK_TERMINALS = ["kitty", "foot", "alacritty", "wezterm", "xterm"]

# terminals whose exec flag is not "-e"
TERMINAL_EXEC_FLAGS = {
    "gnome-terminal": "--",
    "wezterm": "start",  # wezterm start -- <cmd>
}

_cached_terminal: str | None = None


def resolve_terminal(force_refresh: bool = False) -> str | None:
    """Resolves the terminal to use, with an in-memory cache."""
    global _cached_terminal
    if _cached_terminal is not None and not force_refresh:
        return _cached_terminal

    # 1. honour $TERMINAL if set and found in PATH
    env_term = os.environ.get("TERMINAL")
    if env_term and shutil.which(env_term):
        _cached_terminal = env_term
        return _cached_terminal

    # 2. xdg-terminal-exec, if available
    if shutil.which("xdg-terminal-exec"):
        _cached_terminal = "xdg-terminal-exec"
        return _cached_terminal

    # 3. fallback cascade
    for term in FALLBACK_TERMINALS:
        if shutil.which(term):
            _cached_terminal = term
            return _cached_terminal

    _cached_terminal = None
    return None


def build_launch_command(exec_cmd: list[str] | str) -> list[str]:
    """Builds the final command to run exec_cmd inside the resolved terminal."""
    if isinstance(exec_cmd, str):
        exec_cmd = shlex.split(exec_cmd)

    terminal = resolve_terminal()
    if terminal is None:
        raise RuntimeError(
            "No terminal found on the system (set $TERMINAL or install "
            "xdg-terminal-exec / kitty / foot / alacritty / wezterm / xterm)"
        )

    if terminal == "xdg-terminal-exec":
        return ["xdg-terminal-exec", *exec_cmd]

    if terminal == "wezterm":
        return ["wezterm", "start", "--", *exec_cmd]

    flag = TERMINAL_EXEC_FLAGS.get(terminal, "-e")
    return [terminal, flag, *exec_cmd]


def _find_desktop_file(app_name: str) -> str | None:
    """Searches for the .desktop file whose filename matches the app, in XDG dirs."""
    # try direct name first (case-insensitive), then scan everything
    candidates = [f"{app_name}.desktop", f"{app_name.lower()}.desktop"]
    for directory in XDG_APP_DIRS:
        if not os.path.isdir(directory):
            continue
        for candidate in candidates:
            path = os.path.join(directory, candidate)
            if os.path.isfile(path):
                return path
    # fallback: scan all .desktop files looking for a matching Name=
    for directory in XDG_APP_DIRS:
        if not os.path.isdir(directory):
            continue
        for fname in os.listdir(directory):
            if not fname.endswith(".desktop"):
                continue
            path = os.path.join(directory, fname)
            try:
                parser = configparser.ConfigParser(interpolation=None, strict=False)
                parser.read(path, encoding="utf-8")
                entry = parser["Desktop Entry"]
                if entry.get("Name", "").casefold() == app_name.casefold():
                    return path
            except Exception:
                continue
    return None


def app_needs_terminal(app) -> bool:
    """
    Reads Terminal= directly from the original .desktop file, since
    fabric.utils.DesktopApp does not expose that attribute.
    Result is cached per app name.
    """
    app_name = app.name or app.display_name or ""
    if app_name in _terminal_flag_cache:
        return _terminal_flag_cache[app_name]

    needs_terminal = False
    desktop_path = _find_desktop_file(app_name)
    if desktop_path:
        try:
            parser = configparser.ConfigParser(interpolation=None, strict=False)
            parser.read(desktop_path, encoding="utf-8")
            entry = parser["Desktop Entry"]
            needs_terminal = entry.get("Terminal", "false").strip().lower() == "true"
        except Exception:
            needs_terminal = False

    _terminal_flag_cache[app_name] = needs_terminal
    return needs_terminal



_FIELD_CODE_RE = re.compile(r"%[fFuUdDnNickvmhH]")


def _strip_field_codes(cmd: str) -> str:
    """Remove XDG field codes from an Exec string (no files/URLs to substitute)."""
    cmd = cmd.replace("%%", "\x00")
    cmd = _FIELD_CODE_RE.sub("", cmd)
    return " ".join(cmd.replace("\x00", "%").split())


def launch_app(app) -> None:
    """
    Launches a fabric.utils.DesktopApp respecting Terminal=true (read manually
    from the original .desktop file, since Fabric does not expose that
    attribute), using the resolved terminal instead of the lib's default.
    """
    exec_cmd = _strip_field_codes(app.command_line)

    if app_needs_terminal(app):
        cmd = build_launch_command(exec_cmd)
    else:
        cmd = shlex.split(exec_cmd) if isinstance(exec_cmd, str) else exec_cmd

    subprocess.Popen(cmd, start_new_session=True)
