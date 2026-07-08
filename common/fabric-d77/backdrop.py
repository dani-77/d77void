import math
import os

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, Gdk, GdkPixbuf, Gio, GLib, GtkLayerShell

from fabric.utils import get_relative_path
from fabric.widgets.wayland import WaylandWindow

import wallpaper_state

# ══════════════════════════════════════════════════════
# THEME (Tokyo Night) — mirrors wallpaper_selector.py / bar.py
# ══════════════════════════════════════════════════════
COL_BG = (0x1A / 255, 0x1B / 255, 0x26 / 255)
# Qt.darker(#bb9af7, 220) / Qt.darker(#bb9af7, 140), same formula (HSV,
# scales only V) used in the original Backdrop.qml, so the visuals match.
COL_CHEVRON_BACK = (0x55 / 255, 0x46 / 255, 0x70 / 255)
COL_CHEVRON_FRONT = (0x86 / 255, 0x6E / 255, 0xB0 / 255)

LOGO_PATH = get_relative_path("assets/d77-logo.png")
LOGO_SIZE = 180
LOGO_MARGIN = 48
LOGO_OPACITY = 0.25


class Backdrop(WaylandWindow):
    """Decorative background shown only while no wallpaper is active.

    Replica of backdrop/Backdrop.qml from quickshell-d77, but drawn with
    Cairo on a Gtk.DrawingArea instead of QML: GTK3 does not support widget
    rotation via CSS (transform: rotate does not exist in GTK3's CSS engine),
    so the two chevrons are drawn directly, replicating the same math
    (rotation around the rectangle's center, matching QML's default
    transformOrigin: Item.Center).

    Lives on the "bottom" layer-shell layer — above the "background" layer
    where awww-daemon renders the real wallpaper. Does not intercept clicks
    (pass_through=True).
    """

    def __init__(self, **kwargs):
        self._logo_pixbuf = self._load_logo()

        self.drawing_area = Gtk.DrawingArea()
        self.drawing_area.connect("draw", self._on_draw)

        super().__init__(
            layer="bottom",
            anchor="top bottom left right",
            exclusivity="none",
            pass_through=True,
            child=self.drawing_area,
            visible=False,
            **kwargs,
        )

        # exclusivity="none" only means THIS window does not reserve its own
        # exclusive zone — but by default it still respects zones reserved by
        # OTHER layers (e.g. the bar), shrinking to avoid overlapping them.
        # Since this is just decoration behind everything (layer "bottom"),
        # it doesn't matter if the bar draws on top anyway.
        # exclusive_zone=-1 is the layer-shell protocol special value for
        # "ignore exclusive zones from other layers", equivalent to
        # WlrLayershell.exclusionMode: Ignore in the original Backdrop.qml.
        GtkLayerShell.set_exclusive_zone(self, -1)

        # Built with visible=False (actual visibility is decided later in
        # _sync_visibility) — but that means GTK never called show_all(),
        # and a child widget starts invisible by default regardless of its
        # parent window's state. set_visible() on the window only affects
        # the window itself, not its children, so without this the
        # drawing_area would never be rendered. Only needs to run once.
        self.drawing_area.show()

        self._watch_state_file()
        self._sync_visibility()

    def _load_logo(self) -> GdkPixbuf.Pixbuf | None:
        try:
            return GdkPixbuf.Pixbuf.new_from_file(LOGO_PATH)
        except GLib.Error as exc:
            print(f"[backdrop] failed to load '{LOGO_PATH}': {exc}")
            return None

    # -- reactive visibility ------------------------------------------------

    def _watch_state_file(self):
        """Watches the stateFile directory (Gio.FileMonitor cannot reliably
        watch a file that does not yet exist on all backends, so we watch
        the parent directory and filter by filename).
        """
        os.makedirs(wallpaper_state.STATE_DIR, exist_ok=True)
        gfile = Gio.File.new_for_path(wallpaper_state.STATE_DIR)
        self._monitor = gfile.monitor_directory(Gio.FileMonitorFlags.NONE, None)
        self._monitor.connect("changed", self._on_state_dir_changed)

    def _on_state_dir_changed(self, monitor, file, other_file, event_type):
        if file.get_basename() != os.path.basename(wallpaper_state.STATE_FILE):
            return
        self._sync_visibility()

    def _sync_visibility(self):
        has_wallpaper = wallpaper_state.read_current() is not None
        self.set_visible(not has_wallpaper)

    # -- drawing --------------------------------------------------------------

    def _on_draw(self, widget, cr):
        w = widget.get_allocated_width()
        h = widget.get_allocated_height()

        cr.set_source_rgb(*COL_BG)
        cr.paint()

        self._draw_chevron(cr, w, h, 0.68, -0.3, 0.8, 1.6, COL_CHEVRON_BACK)
        self._draw_chevron(cr, w, h, 0.84, -0.2, 0.4, 1.3, COL_CHEVRON_FRONT)
        self._draw_logo(cr, h)

        return False

    def _draw_chevron(self, cr, w, h, fx, fy, fw, fh, color):
        """Rotated rectangle at 35°, replica of the Rectangle items in Backdrop.qml.

        fx/fy/fw/fh are fractions of w/h (x, y, width, height in QML
        coordinates, top-left origin). QML rotation happens around the item's
        own center (default transformOrigin), so we translate to the center
        before rotating.
        """
        rw, rh = fw * w, fh * h
        cx, cy = fx * w + rw / 2, fy * h + rh / 2

        cr.save()
        cr.translate(cx, cy)
        cr.rotate(math.radians(35))
        cr.set_source_rgb(*color)
        cr.rectangle(-rw / 2, -rh / 2, rw, rh)
        cr.fill()
        cr.restore()

    def _draw_logo(self, cr, h):
        if self._logo_pixbuf is None:
            return

        scaled = self._logo_pixbuf.scale_simple(
            LOGO_SIZE, LOGO_SIZE, GdkPixbuf.InterpType.BILINEAR
        )
        x = LOGO_MARGIN
        y = h - LOGO_MARGIN - LOGO_SIZE

        cr.save()
        Gdk.cairo_set_source_pixbuf(cr, scaled, x, y)
        cr.paint_with_alpha(LOGO_OPACITY)
        cr.restore()
