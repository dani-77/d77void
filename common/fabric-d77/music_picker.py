"""Music Picker — fabric-d77.

Search popup to browse albums — sourced from the union of cmus's own live
library (whatever directories have been :add-ed to it, wherever they
live) and a scan of MUSIC_DIR — and start playback of the picked album in
cmus. Mirrors launcher.py's search+list pattern (Entry + filtered
ScrolledWindow), swapping desktop apps for album folders and
launch_app() for cmus_play_album().
Opened from the dashboard's "Browse albums" button (dashboard.py).

Album.artist/title are read from the audio tags (album_artist/artist/album,
via ffprobe on one file per folder) rather than the Artist/Album directory
names, since folder names don't always match the tagged metadata. Falls
back to the directory name whenever ffprobe is missing or a tag is empty.
"""

import operator
import os
import shutil
import subprocess
import threading
from collections.abc import Iterator

from fabric.widgets.box import Box
from fabric.widgets.button import Button
from fabric.widgets.entry import Entry
from fabric.widgets.image import Image
from fabric.widgets.label import Label
from fabric.widgets.scrolledwindow import ScrolledWindow
from fabric.widgets.wayland import WaylandWindow as Window
from fabric.utils import idle_add, remove_handler

from cmus_control import cmus_play_album

def _default_music_dir() -> str:
    """Resolves MUSIC_DIR from `xdg-user-dir MUSIC` so it follows whatever
    the user has configured in user-dirs.dirs instead of being hardcoded
    here; falls back to ~/Música when xdg-user-dir is missing, fails, or
    MUSIC isn't set (xdg-user-dir then just echoes $HOME back).
    """
    home = os.path.expanduser("~")
    if shutil.which("xdg-user-dir"):
        try:
            result = subprocess.run(
                ["xdg-user-dir", "MUSIC"],
                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, timeout=2,
            )
            d = result.stdout.strip()
            if d and d != home:
                return d
        except (OSError, subprocess.TimeoutExpired):
            pass
    return os.path.join(home, "Música")


MUSIC_DIR = _default_music_dir()

_AUDIO_EXTS = (".mp3", ".flac", ".ogg", ".opus", ".m4a", ".wav", ".wma")
_HAVE_FFPROBE = shutil.which("ffprobe") is not None


class Album:
    __slots__ = ("artist", "title", "path")

    def __init__(self, artist: str, title: str, path: str):
        self.artist = artist
        self.title = title
        self.path = path


def _first_audio_file(album_dir: str) -> str | None:
    try:
        entries = sorted(os.listdir(album_dir))
    except OSError:
        return None
    for name in entries:
        if name.lower().endswith(_AUDIO_EXTS):
            path = os.path.join(album_dir, name)
            if os.path.isfile(path):
                return path
    return None


def _read_album_tags(album_dir: str) -> tuple[str | None, str | None]:
    """Reads (artist, album) from the first audio file's tags via ffprobe.

    Prefers the album_artist tag over artist. Returns (None, None) when
    ffprobe isn't installed, no audio file is found, or the file carries
    none of these tags — callers fall back to the directory name.
    """
    if not _HAVE_FFPROBE:
        return None, None
    audio_file = _first_audio_file(album_dir)
    if audio_file is None:
        return None, None
    try:
        result = subprocess.run(
            [
                "ffprobe", "-v", "error",
                "-show_entries", "format_tags=album_artist,artist,album",
                "-of", "default=noprint_wrappers=1:nokey=0",
                audio_file,
            ],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, timeout=5,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None, None
    if result.returncode != 0:
        return None, None
    tags: dict[str, str] = {}
    for line in result.stdout.splitlines():
        if line.startswith("TAG:"):
            key, _, value = line[4:].partition("=")
            tags[key.lower()] = value.strip()
    return tags.get("album_artist") or tags.get("artist") or None, tags.get("album") or None


def _cmus_library_dirs() -> set[str]:
    """Returns the set of directories holding every file in cmus's live
    library (`cmus-remote -C "save -l -"`, a plain path-per-line dump) —
    however many separate roots the user has :add-ed, wherever they live
    (~/Música, ~/Audio, a mounted drive, ...). Empty when cmus isn't
    running or its library has nothing in it.
    """
    try:
        result = subprocess.run(
            ["cmus-remote", "-C", "save -l -"],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, timeout=5,
        )
    except (OSError, subprocess.TimeoutExpired):
        return set()
    if result.returncode != 0:
        return set()
    return {
        os.path.dirname(line) for line in result.stdout.splitlines() if line.strip()
    }


def _scan_albums(root: str) -> list[Album]:
    """Album directories are the union of cmus's own live library (see
    _cmus_library_dirs) and a hand walk of root for directories directly
    containing audio files — any depth, so this covers both a flat layout
    (Album folders straight under root) and a nested one (Artist/Album, or
    deeper). Deduplicated, so a directory in both is only listed once —
    this way nothing is hidden just because it hasn't been :add-ed to cmus
    yet, and nothing outside root is hidden just because cmus isn't running.
    The last path segment of a directory is always the album folder; the
    one above it (if any) is the artist folder, used whenever ffprobe tags
    don't supply one.
    The same album can also physically live under more than one directory
    (e.g. an unsorted import folder alongside its organized copy under
    root) — directory-path dedup above can't catch that since the paths
    genuinely differ, so entries are further deduped by (artist, album)
    tag identity below, keeping the first one found.
    """
    album_dirs: set[str] = _cmus_library_dirs()
    if os.path.isdir(root):
        for dirpath, _dirnames, filenames in os.walk(root):
            if any(name.lower().endswith(_AUDIO_EXTS) for name in filenames):
                album_dirs.add(dirpath)

    albums = []
    seen: set[tuple[str, str]] = set()
    for album_dir in sorted(album_dirs):
        parts = album_dir.rstrip(os.sep).split(os.sep)
        dir_album = parts[-1]
        dir_artist = parts[-2] if len(parts) > 1 else "Unknown Artist"
        tag_artist, tag_album = _read_album_tags(album_dir)
        artist = tag_artist or dir_artist
        title = tag_album or dir_album
        key = (artist.casefold(), title.casefold())
        if key in seen:
            continue
        seen.add(key)
        albums.append(Album(artist, title, album_dir))
    return albums


class MusicPicker(Window):
    def __init__(self, **kwargs):
        super().__init__(
            layer="top",
            anchor="center",
            exclusivity="none",
            keyboard_mode="on-demand",
            visible=False,
            all_visible=False,
            **kwargs,
        )
        self._arranger_handler: int = 0
        self._all_albums = _scan_albums(MUSIC_DIR)

        self.viewport = Box(spacing=2, orientation="v")
        self.search_entry = Entry(
            placeholder="Search Artist / Album...",
            h_expand=True,
            notify_text=lambda entry, *_: self.arrange_viewport(entry.get_text()),
        )
        self.scrolled_window = ScrolledWindow(
            min_content_size=(320, 360),
            max_content_size=(320 * 2, 360),
            child=self.viewport,
        )

        self.add(
            Box(
                name="launcher-window",
                spacing=2,
                orientation="v",
                style="margin: 2px",
                children=[
                    Box(
                        spacing=2,
                        orientation="h",
                        children=[
                            self.search_entry,
                            Button(
                                image=Image(icon_name="window-close"),
                                tooltip_text="Exit",
                                on_clicked=lambda *_: self.set_visible(False),
                            ),
                        ],
                    ),
                    self.scrolled_window,
                ],
            )
        )
        self.add_keybinding("escape", lambda *_: self.set_visible(False))
        self.show_all()

    def refresh_albums(self):
        self._all_albums = _scan_albums(MUSIC_DIR)
        self.search_entry.set_text("")
        self.arrange_viewport("")

    def arrange_viewport(self, query: str = ""):
        remove_handler(self._arranger_handler) if self._arranger_handler else None
        self.viewport.children = []

        filtered_iter = iter(
            [
                album
                for album in self._all_albums
                if query.casefold() in f"{album.artist} {album.title}".casefold()
            ]
        )
        should_resize = operator.length_hint(filtered_iter) == len(self._all_albums)

        self._arranger_handler = idle_add(
            lambda *args: self.add_next_album(*args)
            or (self.resize_viewport() if should_resize else False),
            filtered_iter,
            pin=True,
        )
        return False

    def add_next_album(self, albums_iter: Iterator[Album]):
        if not (album := next(albums_iter, None)):
            return False
        self.viewport.add(self.bake_album_slot(album))
        return True

    def resize_viewport(self):
        self.scrolled_window.set_min_content_width(
            self.viewport.get_allocation().width  # type: ignore
        )
        return False

    def bake_album_slot(self, album: Album, **kwargs) -> Button:
        return Button(
            child=Box(
                orientation="h",
                spacing=12,
                children=[
                    Image(icon_name="audio-x-generic-symbolic", h_align="start", icon_size=32),
                    Label(
                        label=f"{album.artist} — {album.title}",
                        v_align="center",
                        h_align="center",
                    ),
                ],
            ),
            tooltip_text=album.path,
            on_clicked=lambda *_: (
                threading.Thread(
                    target=cmus_play_album, args=(album.path,), daemon=True
                ).start(),
                self.set_visible(False),
            ),
            **kwargs,
        )

    def toggle(self):
        if self.get_visible():
            self.set_visible(False)
        else:
            self.show_all()
            self.refresh_albums()
            self.set_visible(True)
            self.search_entry.grab_focus()
