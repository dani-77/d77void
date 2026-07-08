import os
import subprocess

from fabric.widgets.box import Box
from fabric.widgets.button import Button
from fabric.widgets.image import Image
from fabric.widgets.label import Label
from fabric.widgets.scrolledwindow import ScrolledWindow
from fabric.widgets.wayland import WaylandWindow as Window
from gi.repository import GLib

import wallpaper_state

# Wallpaper directory. Change this path if yours is different.
WALLPAPER_DIR = os.path.expanduser("~/Wallpaper")

# Accepted image extensions
VALID_EXTENSIONS = (".png", ".jpg", ".jpeg", ".webp", ".bmp")

THUMB_SIZE = 160
COLUMNS = 4

# Color (RRGGBB, no '#') used by awww when clearing — Tokyo Night colBg,
# same as Backdrop (backdrop.py). awww has no concept of "no wallpaper",
# only "image" or "solid color"; whether the decorative backdrop appears
# on top is decided by the state file (wallpaper_state).
CLEAR_COLOR = "1a1b26"


class WallpaperSelector(Window):
    """Wallpaper grid (DankMaterialShell style) that applies via awww on click.

    Standalone layer-shell window, following the same pattern as SessionMenu:
    centered overlay, keyboard_mode on-demand, escape to close.
    """

    def __init__(self, **kwargs):
        super().__init__(
            layer="overlay",
            anchor="center",
            exclusivity="none",
            keyboard_mode="on-demand",
            visible=False,
            all_visible=False,
            **kwargs,
        )

        self.current_wallpaper: str | None = wallpaper_state.read_current()

        self.grid_box = Box(
            name="wallpaper-grid",
            orientation="v",
            spacing=8,
        )

        self.scrolled = ScrolledWindow(
            name="wallpaper-scroll",
            child=self.grid_box,
            h_expand=True,
            v_expand=True,
            min_content_width=COLUMNS * (THUMB_SIZE + 16),
            min_content_height=600,
        )

        self.title_label = Label(
            name="wallpaper-title",
            label="Wallpapers",
            h_align="start",
        )

        self.clear_button = Button(
            name="wallpaper-clear-button",
            child=Box(
                orientation="h",
                spacing=6,
                children=[
                    Image(icon_name="edit-clear-all-symbolic", icon_size=14),
                    Label(label="Clear"),
                ],
            ),
            on_clicked=lambda *_: self.clear_wallpaper(),
        )

        self.header_row = Box(
            orientation="h",
            spacing=8,
            children=[
                self.title_label,
                Box(h_expand=True),
                self.clear_button,
            ],
        )

        self.add(
            Box(
                name="wallpaper-selector",
                orientation="v",
                spacing=12,
                children=[
                    self.header_row,
                    self.scrolled,
                ],
            )
        )

        self.add_keybinding("escape", lambda *_: self.set_visible(False))

        print("[wallpaper_selector] __init__: calling populate()")
        self.populate()
        print("[wallpaper_selector] __init__: calling show_all()")
        self.show_all()
        print("[wallpaper_selector] __init__: done")

    # -- listing / grid -------------------------------------------------

    def list_wallpapers(self) -> list[str]:
        if not os.path.isdir(WALLPAPER_DIR):
            return []
        files = [
            os.path.join(WALLPAPER_DIR, f)
            for f in sorted(os.listdir(WALLPAPER_DIR))
            if f.lower().endswith(VALID_EXTENSIONS)
        ]
        return files

    def populate(self):
        print("[wallpaper_selector] populate() started")
        # clear current grid before repopulating (allows refresh())
        for child in list(self.grid_box.children):
            self.grid_box.remove(child)

        wallpapers = self.list_wallpapers()
        print(f"[wallpaper_selector] {len(wallpapers)} wallpapers found")

        if not wallpapers:
            self.grid_box.add(
                Label(
                    name="wallpaper-empty",
                    label=f"No images found in {WALLPAPER_DIR}",
                )
            )
            print("[wallpaper_selector] populate() done (no wallpapers)")
            return

        row = None
        for i, path in enumerate(wallpapers):
            if i % COLUMNS == 0:
                row = Box(orientation="h", spacing=8)
                self.grid_box.add(row)
            try:
                row.add(self.bake_thumbnail(path))
            except Exception as exc:
                print(f"[wallpaper_selector] ERROR creating thumbnail for {path}: {exc}")
        print("[wallpaper_selector] populate() done")

    def bake_thumbnail(self, path: str) -> Button:
        try:
            thumb = Image(
                image_file=path,
                size=THUMB_SIZE,
            )
        except Exception as exc:
            # File has an image extension but invalid format or no loader
            # (e.g. webp without gdk-pixbuf-webp, corrupted file, broken
            # symlink). Don't let this bring down the whole selector.
            print(f"[wallpaper_selector] failed to load '{path}': {exc}")
            thumb = Label(label="⚠", name="wallpaper-thumb-error")

        is_current = path == self.current_wallpaper

        btn = Button(
            name="wallpaper-thumb-selected" if is_current else "wallpaper-thumb",
            child=Box(
                orientation="v",
                spacing=4,
                children=[
                    thumb,
                    Label(
                        label=os.path.basename(path),
                        name="wallpaper-thumb-label",
                    ),
                ],
            ),
            on_clicked=lambda *_, p=path: self.apply_wallpaper(p),
        )
        return btn

    # -- apply wallpaper -------------------------------------------------

    def apply_wallpaper(self, path: str):
        """Applies the wallpaper via awww asynchronously (non-blocking)."""
        try:
            subprocess.Popen(
                ["awww", "img", path],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except FileNotFoundError:
            self.title_label.set_label("Error: awww not found in PATH")
            return

        wallpaper_state.write_current(path)
        self.current_wallpaper = path
        self.title_label.set_label(f"Wallpapers — {os.path.basename(path)}")
        # re-render to highlight the selected thumbnail
        GLib.idle_add(self.populate)
        self.set_visible(False)

    def clear_wallpaper(self):
        """Clears the active wallpaper: fills awww with colBg and removes the
        saved state so Backdrop (backdrop.py) becomes visible again.
        """
        try:
            subprocess.Popen(
                ["awww", "clear", CLEAR_COLOR],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except FileNotFoundError:
            self.title_label.set_label("Error: awww not found in PATH")
            return

        wallpaper_state.clear_current()
        self.current_wallpaper = None
        self.title_label.set_label("Wallpapers")
        GLib.idle_add(self.populate)
        self.set_visible(False)

    def refresh(self):
        """Repopulates the grid (call on reopen to pick up new files)."""
        self.populate()
        self.show_all()

    def toggle(self):
        if self.get_visible():
            self.set_visible(False)
        else:
            self.refresh()
            self.set_visible(True)
