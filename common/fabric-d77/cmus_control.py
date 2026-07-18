"""Shared cmus control helpers.

Used by dashboard.py (status polling + track/album controls) and
music_picker.py (starting playback of a picked album). Pulled out of
dashboard.py once a second module needed the same cmus-remote plumbing.

cmus-remote finds its control socket via XDG_RUNTIME_DIR (or ~/.config/cmus
as a fallback), so every call here needs an environment that actually
matches whatever cmus itself is running with — see _discover_cmus_env().
"""

import os
import subprocess
import time

_ENV_KEYS = ("XDG_RUNTIME_DIR", "HOME")
_cmus_env_cache: dict[str, str] = {}


def _cmus_pid() -> str | None:
    """Finds the running cmus process's PID, via pgrep falling back to ps."""
    try:
        result = subprocess.run(
            ["pgrep", "-x", "cmus"],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
        )
        pid = result.stdout.split()
        if pid:
            return pid[0]
    except OSError:
        pass
    try:
        result = subprocess.run(
            ["ps", "-eo", "pid,comm"],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
        )
    except OSError:
        return None
    for line in result.stdout.splitlines()[1:]:
        parts = line.split(None, 1)
        if len(parts) == 2 and parts[1].strip() == "cmus":
            return parts[0]
    return None


def _discover_cmus_env() -> dict[str, str]:
    """Reads XDG_RUNTIME_DIR/HOME from the running cmus process's own
    environment (/proc/<pid>/environ) instead of assuming it matches ours.

    A tmux/screen-hosted cmus can outlive a logout/compositor switch and end
    up with a different runtime dir than our own process — its own
    environment is the only reliable source of truth for where its control
    socket actually lives. Updates and returns the module-level cache;
    leaves it (and returns the last known values) untouched if cmus can't
    be found right now.
    """
    pid = _cmus_pid()
    if pid is None:
        return _cmus_env_cache
    try:
        with open(f"/proc/{pid}/environ", "rb") as f:
            data = f.read()
    except OSError:
        return _cmus_env_cache
    found: dict[str, str] = {}
    for entry in data.split(b"\0"):
        for key in _ENV_KEYS:
            prefix = f"{key}=".encode()
            if entry.startswith(prefix):
                found[key] = entry[len(prefix):].decode(errors="replace")
    if found:
        _cmus_env_cache.update(found)
    return _cmus_env_cache


def _cmus_remote_env() -> dict[str, str]:
    """Environment for cmus-remote calls: our own, with XDG_RUNTIME_DIR/HOME
    overridden by whatever was last discovered from the running cmus process.
    Falls back to plain os.environ untouched when nothing's been discovered
    yet (e.g. before cmus has ever been found running).
    """
    env = os.environ.copy()
    env.update(_cmus_env_cache)
    return env


def cmus_status() -> tuple[bool, str, str]:
    """Returns (running, status, track)."""
    try:
        result = subprocess.run(
            ["cmus-remote", "-Q"],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
            env=_cmus_remote_env(),
        )
        if result.returncode != 0:
            # Cached env may be stale (e.g. cmus was restarted outside
            # start_cmus_headless()) — rediscover for the next call.
            _discover_cmus_env()
            return False, "stopped", "—"
        status = "stopped"
        artist = title = ""
        for line in result.stdout.splitlines():
            if line.startswith("status "):
                status = line.split(" ", 1)[1].strip()
            elif line.startswith("tag artist "):
                artist = line.split(" ", 2)[2].strip()
            elif line.startswith("tag title "):
                title = line.split(" ", 2)[2].strip()
        track = f"{artist} — {title}" if artist and title else title or "—"
        if len(track) > 42:
            track = track[:40] + "…"
        return True, status, track
    except Exception:
        return False, "stopped", "—"


def cmus_current_album() -> tuple[str | None, str | None]:
    """Returns (status, album tag) of the current track, or (None, None) on failure."""
    result = subprocess.run(
        ["cmus-remote", "-Q"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
        env=_cmus_remote_env(),
    )
    if result.returncode != 0:
        _discover_cmus_env()
        return None, None
    status = album = None
    for line in result.stdout.splitlines():
        if line.startswith("status "):
            status = line.split(" ", 1)[1].strip()
        elif line.startswith("tag album "):
            album = line.split(" ", 2)[2].strip()
    return status, album


def cmus_prev():
    subprocess.run(["cmus-remote", "-r"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                   env=_cmus_remote_env())


def cmus_toggle():
    subprocess.run(["cmus-remote", "-u"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                   env=_cmus_remote_env())


def cmus_next():
    subprocess.run(["cmus-remote", "-n"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                   env=_cmus_remote_env())


def cmus_skip_album(direction: int, max_steps: int = 300):
    """Skips forward/backward by a whole album (direction=+1/-1).

    cmus has no native "next/previous album" command, so this steps track by
    track via cmus-remote until the "album" tag changes, relying on the
    library/queue being album-ordered (true when browsing a directory tree of
    many albums, which is the case this is meant for). Runs in a background
    thread since it may issue many cmus-remote calls in a row.
    """
    step_args = ["-n"] if direction > 0 else ["-r"]
    start_status, start_album = cmus_current_album()
    if start_status is None:
        return
    if start_album is None:
        # No album tag to key off — fall back to a plain track skip.
        subprocess.run(["cmus-remote"] + step_args,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       env=_cmus_remote_env())
        return
    for _ in range(max_steps):
        subprocess.run(["cmus-remote"] + step_args,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       env=_cmus_remote_env())
        status, album = cmus_current_album()
        if status is None or status == "stopped":
            return
        if album is not None and album != start_album:
            return


def start_cmus_headless():
    """Starts cmus in a detached tmux or screen session.

    Kills any existing "cmus" session first (even orphaned ones) and passes
    XDG_RUNTIME_DIR/HOME explicitly to cmus from our own environment — the
    only point where there's no running cmus process yet to read them back
    from. Every cmus-remote call afterwards instead follows whatever
    _discover_cmus_env() reads back from that freshly started process (see
    cmus_play_album), rather than continuing to assume our own environment
    still matches.
    """
    _cmus_env_cache.clear()
    env_prefix = (
        f"XDG_RUNTIME_DIR={os.environ.get('XDG_RUNTIME_DIR', '')} "
        f"HOME={os.environ.get('HOME', '')} "
    )
    script = (
        "tmux kill-session -t cmus >/dev/null 2>&1; "
        f'command -v tmux >/dev/null 2>&1 && {{ tmux new-session -d -s cmus "{env_prefix}cmus"; exit 0; }}; '
        f'command -v screen >/dev/null 2>&1 && {{ screen -dmS cmus sh -c "{env_prefix}exec cmus"; exit 0; }}; '
        "exit 1"
    )
    subprocess.Popen(
        ["sh", "-c", script],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )


def cmus_play_album(album_dir: str):
    """Clears cmus's play queue and queues every track under album_dir.

    Uses the play queue (-q) rather than the playlist: -p alone just resumes
    whatever cmus's current view (Library, by default here) was already on,
    ignoring playlist changes entirely — verified by hand, it silently kept
    playing the previous album. The play queue always takes priority over
    the active view regardless of playback state, so this reliably jumps
    straight to the picked album.

    Starts cmus headless first if it isn't reachable yet, polling briefly for
    its control socket to come up. Intended to run off the GTK main thread —
    the wait loop can take a couple seconds.
    """
    running, _, _ = cmus_status()
    if not running:
        start_cmus_headless()
        for _ in range(20):
            time.sleep(0.25)
            running, _, _ = cmus_status()
            if running:
                # Lock in the freshly started process's actual environment
                # rather than keep relying on cmus_status()'s fallback.
                _discover_cmus_env()
                break

    def run(*args):
        subprocess.run(["cmus-remote", *args],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       env=_cmus_remote_env())

    run("-q", "-c")
    run("-q", album_dir)
    run("-n")
    run("-p")
