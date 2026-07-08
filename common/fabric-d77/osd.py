"""On-Screen Display (OSD) for volume, brightness and power profile — fabric-d77.

Minimal overlay (icon + progress bar + percentage) that appears in the top-right
corner whenever volume, screen brightness or the power profile changes, and
auto-hides after a few seconds.

Backends (intentionally independent of the audio server, mirroring the
equivalent module in quickshell-d77):

* Volume  -> ALSA via ``amixer`` (with mute/unmute support).
* Brightness -> ``brightnessctl``.
* Power profile -> ``powerprofilesctl``.

How it works:

* A ``Fabricator`` polls volume/mute, brightness and power profile periodically.
  Whenever a change is detected (even one triggered externally — e.g. media
  keys wired directly to ``amixer``/``brightnessctl``, or another app changing
  the volume/profile) the corresponding OSD is shown.
* The OSD also exposes public methods (:meth:`OSD.volume_up`,
  :meth:`OSD.volume_down`, :meth:`OSD.volume_mute_toggle`,
  :meth:`OSD.brightness_up`, :meth:`OSD.brightness_down`,
  :meth:`OSD.power_profile_cycle`) for callers that prefer the shell to apply
  the change and show the OSD immediately.

The window is a layer-shell ``WaylandWindow`` on the *overlay* layer, anchored
top-right, with ``pass_through=True`` so it does not block the pointer.
"""

import re
import subprocess

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import GLib  # noqa: E402

from fabric.widgets.box import Box  # noqa: E402
from fabric.widgets.image import Image  # noqa: E402
from fabric.widgets.label import Label  # noqa: E402
from fabric.widgets.scale import Scale  # noqa: E402
from fabric.widgets.wayland import WaylandWindow as Window  # noqa: E402
from fabric.core.fabricator import Fabricator  # noqa: E402


# ── Configuration ────────────────────────────────────────────────────────────
MIXER_CONTROL = "Master"   # ALSA control used by amixer
STEP = 5                   # step (%) for volume and brightness up/down
TIMEOUT_MS = 2500          # time (ms) the OSD stays visible
POLL_INTERVAL_MS = 300     # polling interval to detect external changes


# ── Backend helpers ──────────────────────────────────────────────────────────
def _run(cmd: list[str]) -> str:
    """Runs a command and returns stdout as a string. Returns "" on failure."""
    try:
        return subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            check=False,
        ).stdout
    except Exception:
        return ""


def get_volume() -> tuple[int, bool]:
    """Reads volume (0-100) and mute state via ALSA.

    Returns ``(level, muted)``. Returns ``(0, False)`` on error.
    """
    out = _run(["amixer", "get", MIXER_CONTROL])
    if not out:
        return 0, False

    level = 0
    muted = False
    for line in out.splitlines():
        if "%]" in line:
            # e.g.: "  Front Left: Playback 32768 [50%] [on]"
            try:
                seg = line.split("[")[1]          # "50%] ..."
                level = int(seg.split("%")[0])
            except (IndexError, ValueError):
                pass
            if "[off]" in line:
                muted = True
            break
    return level, muted


POWER_PROFILES = ["performance", "balanced", "power-saver"]


def get_power_profile() -> str:
    """Reads the active power profile via D-Bus (net.hadess.PowerProfiles).

    Uses ``gdbus`` (native binary, ~20ms) instead of ``powerprofilesctl``
    (Python script, ~500ms) because this function runs on every polling cycle
    (every :data:`POLL_INTERVAL_MS`) — with ``powerprofilesctl`` the polling
    time itself exceeded the interval and blocked the GLib main loop,
    preventing the entire shell from rendering windows.

    Returns "" on error (treated as "unavailable").
    """
    out = _run([
        "gdbus", "call", "--system",
        "--dest", "net.hadess.PowerProfiles",
        "--object-path", "/net/hadess/PowerProfiles",
        "--method", "org.freedesktop.DBus.Properties.Get",
        "net.hadess.PowerProfiles", "ActiveProfile",
    ])
    match = re.search(r"'([^']+)'", out)
    profile = match.group(1) if match else ""
    return profile if profile in POWER_PROFILES else ""


def get_brightness() -> int:
    """Reads current brightness (0-100) via ``brightnessctl``.

    Uses machine-readable output (``-m``): field 4 = percentage.
    Returns -1 on error (treated as "unavailable").
    """
    out = _run(["brightnessctl", "-m"]).strip()
    if not out:
        return -1
    try:
        # e.g.: "intel_backlight,backlight,3000,40%,7500"
        parts = out.split(",")
        return int(parts[3].rstrip("%"))
    except (IndexError, ValueError):
        return -1


class OSD(Window):
    """OSD overlay window (volume + brightness)."""

    def __init__(self, **kwargs):
        # IMPORTANT: initialise the GObject base (WaylandWindow) first.
        # Since OSD inherits from Gtk.Window (via Fabric), the object must be
        # initialised *before* creating/assigning widgets or adding children —
        # otherwise GObject raises
        # "RuntimeError: object ... of type OSD is not initialized".
        # This is the same pattern used by SessionMenu and StatusBar.
        super().__init__(
            name="osd-window",
            layer="overlay",
            anchor="top right",
            margin="16px 16px 0px 0px",
            exclusivity="none",
            pass_through=True,   # does not block pointer events
            visible=False,
            all_visible=False,
            **kwargs,
        )

        # ── Icon ─────────────────────────────────────────────────────────────
        self.icon = Image(
            name="osd-icon",
            icon_name="audio-volume-high-symbolic",
            icon_size=24,
        )

        # ── Progress bar (non-interactive Scale) ─────────────────────────────
        self.scale = Scale(
            name="osd-scale",
            value=0.0,
            min_value=0.0,
            max_value=100.0,
            orientation="h",
            draw_value=False,
            h_expand=True,
        )
        # Non-interactive: used as a progress bar only.
        self.scale.set_sensitive(False)

        # ── Percentage label ──────────────────────────────────────────────────
        self.label = Label(name="osd-label", label="0%")

        # NOTE: the attribute must NOT be named ``self.container`` — that name
        # collides with a read-only introspected GObject/Gtk field, causing
        # "RuntimeError: field is not writable". Using ``self.box`` instead.
        self.box = Box(
            name="osd-box",
            orientation="h",
            spacing=12,
            children=[self.icon, self.scale, self.label],
        )

        # Add content to the already-initialised window.
        self.children = self.box

        # ── State ─────────────────────────────────────────────────────────────
        self._hide_timer: int | None = None
        # Initial baseline (don't show OSD on startup; only on future changes).
        self._last_vol, self._last_muted = get_volume()
        self._last_bri = get_brightness()
        self._last_profile = get_power_profile()

        # ── Polling to detect external changes ───────────────────────────────
        self._watcher = Fabricator(
            interval=POLL_INTERVAL_MS,
            poll_from=lambda *_: (get_volume(), get_brightness(), get_power_profile()),
            on_changed=self._on_poll,
            default_value=(
                (self._last_vol, self._last_muted),
                self._last_bri,
                self._last_profile,
            ),
        )

    # ── Polling ──────────────────────────────────────────────────────────────
    def _on_poll(self, _, value):
        (vol, muted), bri, profile = value

        vol_changed = (vol != self._last_vol) or (muted != self._last_muted)
        bri_changed = (bri != self._last_bri) and (bri >= 0)
        profile_changed = (profile != self._last_profile) and profile

        # Brightness takes priority if both change in the same cycle (rare).
        if bri_changed:
            self._last_bri = bri
            self._show_brightness(bri)
        if vol_changed:
            self._last_vol, self._last_muted = vol, muted
            self._show_volume(vol, muted)
        if profile_changed:
            self._last_profile = profile
            self._show_power_profile(profile)

    # ── Display ──────────────────────────────────────────────────────────────
    def _volume_icon(self, level: int, muted: bool) -> str:
        if muted or level == 0:
            return "audio-volume-muted-symbolic"
        if level < 34:
            return "audio-volume-low-symbolic"
        if level < 67:
            return "audio-volume-medium-symbolic"
        return "audio-volume-high-symbolic"

    def _power_profile_icon(self, profile: str) -> str:
        return f"power-profile-{profile}-symbolic"

    def _brightness_icon(self, level: int) -> str:
        if level < 34:
            return "display-brightness-low-symbolic"
        if level < 67:
            return "display-brightness-medium-symbolic"
        return "display-brightness-high-symbolic"

    def _show_volume(self, level: int, muted: bool):
        self.scale.set_visible(True)
        self.icon.set_from_icon_name(self._volume_icon(level, muted), 24)
        self.scale.set_value(0 if muted else level)
        self.label.set_label("mute" if muted else f"{level}%")
        self._set_mode_class("volume", muted)
        self._reveal()

    def _show_brightness(self, level: int):
        self.scale.set_visible(True)
        self.icon.set_from_icon_name(self._brightness_icon(level), 24)
        self.scale.set_value(level)
        self.label.set_label(f"{level}%")
        self._set_mode_class("brightness", False)
        self._reveal()

    def _show_power_profile(self, profile: str):
        # Power profile is a discrete state, not a percentage — hide the
        # progress bar and show only icon + name.
        self.scale.set_visible(False)
        self.icon.set_from_icon_name(self._power_profile_icon(profile), 24)
        self.label.set_label(profile.replace("-", " ").title())
        self._set_mode_class("power", False)
        self._reveal()

    def _set_mode_class(self, mode: str, muted: bool):
        # Allows styling volume/brightness/mute/power differently via CSS.
        for cls in ("volume", "brightness", "power", "muted"):
            self.box.remove_style_class(cls)
            self.scale.remove_style_class(cls)
        self.box.add_style_class(mode)
        self.scale.add_style_class(mode)
        if muted:
            self.box.add_style_class("muted")
            self.scale.add_style_class("muted")

    def _reveal(self):
        self.set_visible(True)
        if self._hide_timer is not None:
            GLib.source_remove(self._hide_timer)
        self._hide_timer = GLib.timeout_add(TIMEOUT_MS, self._hide)

    def _hide(self):
        self.set_visible(False)
        self._hide_timer = None
        return False

    # ── Public API (shell can apply the change and show the OSD immediately) ─
    def volume_up(self, *_):
        _run(["amixer", "set", MIXER_CONTROL, f"{STEP}%+", "unmute"])
        self._refresh_volume()

    def volume_down(self, *_):
        _run(["amixer", "set", MIXER_CONTROL, f"{STEP}%-"])
        self._refresh_volume()

    def volume_mute_toggle(self, *_):
        _run(["amixer", "set", MIXER_CONTROL, "toggle"])
        self._refresh_volume()

    def brightness_up(self, *_):
        _run(["brightnessctl", "set", f"{STEP}%+"])
        self._refresh_brightness()

    def brightness_down(self, *_):
        _run(["brightnessctl", "set", f"{STEP}%-"])
        self._refresh_brightness()

    def power_profile_cycle(self, *_):
        current = get_power_profile() or self._last_profile
        try:
            next_profile = POWER_PROFILES[(POWER_PROFILES.index(current) + 1) % len(POWER_PROFILES)]
        except ValueError:
            next_profile = POWER_PROFILES[0]
        _run(["powerprofilesctl", "set", next_profile])
        self._refresh_power_profile()

    def _refresh_volume(self):
        vol, muted = get_volume()
        self._last_vol, self._last_muted = vol, muted
        self._show_volume(vol, muted)

    def _refresh_brightness(self):
        bri = get_brightness()
        if bri >= 0:
            self._last_bri = bri
            self._show_brightness(bri)

    def _refresh_power_profile(self):
        profile = get_power_profile()
        if profile:
            self._last_profile = profile
            self._show_power_profile(profile)


if __name__ == "__main__":
    # Standalone run to test the OSD outside the main shell.
    from fabric import Application
    from fabric.utils import get_relative_path

    osd = OSD()
    app = Application("d77-osd", osd)

    style_path = get_relative_path("./style.css")
    try:
        app.set_stylesheet_from_file(style_path)
    except Exception:
        pass

    app.run()
