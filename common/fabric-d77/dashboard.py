"""Info Dashboard — fabric-d77.

Centered overlay with system stats (CPU, RAM, temperature, disk),
weather, cmus controls and a quick nmtui launcher.
Triggered by SIGRTMIN+7 in main.py via dashboard.toggle().
"""

import os
import subprocess
import threading
import urllib.request

import psutil

from gi.repository import GLib

import session_actions
from fabric.core.fabricator import Fabricator
from fabric.widgets.box import Box
from fabric.widgets.button import Button
from fabric.widgets.image import Image
from fabric.widgets.label import Label
from fabric.widgets.wayland import WaylandWindow as Window


# ── Helpers ───────────────────────────────────────────────────────────────────

def _get_cpu_temp() -> str:
    try:
        temps = psutil.sensors_temperatures()
        for key in ("coretemp", "k10temp", "acpitz", "cpu_thermal"):
            if key in temps and temps[key]:
                return f"{temps[key][0].current:.0f}°C"
    except Exception:
        pass
    return "N/A"


def _get_disk_percent() -> int:
    try:
        return int(psutil.disk_usage("/").percent)
    except Exception:
        return 0


def _fetch_weather_sync() -> str:
    try:
        req = urllib.request.Request(
            "https://wttr.in/?format=3",
            headers={"User-Agent": "curl/7.0"},
        )
        with urllib.request.urlopen(req, timeout=6) as resp:
            return resp.read().decode("utf-8").strip()
    except Exception:
        return "weather unavailable"


def _cmus_status() -> tuple[bool, str, str]:
    """Returns (running, status, track)."""
    try:
        result = subprocess.run(
            ["cmus-remote", "-Q"],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
        )
        if result.returncode != 0:
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


def _start_cmus_headless():
    """Starts cmus in a detached tmux or screen session.

    Kills any existing "cmus" session first (even orphaned ones) and passes
    XDG_RUNTIME_DIR/HOME explicitly to cmus: a tmux server that survives a
    logout/compositor switch keeps the environment it was originally launched
    with, causing cmus to write its control socket to a path that the current
    cmus-remote can no longer find.
    """
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


def _get_net_status() -> tuple[str, str]:
    """Returns (icon_name, label). Checks WiFi then Ethernet."""
    try:
        net_root = "/sys/class/net"
        for iface in os.listdir(net_root):
            if os.path.isdir(os.path.join(net_root, iface, "wireless")):
                out = subprocess.run(
                    ["iw", "dev", iface, "link"],
                    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
                ).stdout
                for line in out.splitlines():
                    line = line.strip()
                    if line.startswith("SSID:"):
                        ssid = line.split(":", 1)[1].strip()
                        if len(ssid) > 22:
                            ssid = ssid[:20] + "…"
                        return "network-wireless-symbolic", f"Connected to {ssid}"
        for iface in os.listdir(net_root):
            if iface == "lo":
                continue
            iface_path = os.path.join(net_root, iface)
            if os.path.isdir(os.path.join(iface_path, "wireless")):
                continue
            if not os.path.exists(os.path.join(iface_path, "device")):
                continue
            carrier = os.path.join(iface_path, "carrier")
            if os.path.exists(carrier):
                with open(carrier) as f:
                    if f.read().strip() == "1":
                        return "network-wired-symbolic", f"Connected ({iface})"
    except Exception:
        pass
    return "network-wireless-offline-symbolic", "Network configuration"


def _launch_nmtui():
    candidates = [
        ("foot",      ["--app-id=nmtui-float"]),
        ("kitty",     ["--class=nmtui-float"]),
        ("alacritty", ["--class=nmtui-float", "-e"]),
        ("wezterm",   ["start", "--class", "nmtui-float", "--"]),
        ("xterm",     ["-class", "nmtui-float", "-e"]),
    ]
    for exe, args in candidates:
        try:
            subprocess.run(["which", exe], check=True,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            os.system(" ".join([exe] + args + ["nmtui &"]))
            return
        except subprocess.CalledProcessError:
            pass


# ── Construction Helpers ─────────────────────────────────────────────────────

def _stat_card(icon_name: str, value_label: Label, title: str) -> Box:
    card = Box(
        name="dashboard-card",
        orientation="v",
        spacing=4,
        h_align="center",
        children=[
            Image(icon_name=icon_name, icon_size=32),
            value_label,
            Label(name="dashboard-card-title", label=title, h_align="center"),
        ],
    )
    card.set_hexpand(True)
    return card


# ── Widget ────────────────────────────────────────────────────────────────────

class InfoDashboard(Window):
    """Quick-info panel triggered by SIGRTMIN+7."""

    def __init__(self, on_lock=None, **kwargs):
        super().__init__(
            layer="overlay",
            anchor="top left",
            margin="10px 0px 0px 10px",
            exclusivity="none",
            keyboard_mode="on-demand",
            visible=False,
            all_visible=False,
            **kwargs,
        )

        # ── System stats ─────────────────────────────────────────────────────
        self._cpu_val  = Label(name="dashboard-card-value", label="—", h_align="center")
        self._ram_val  = Label(name="dashboard-card-value", label="—", h_align="center")
        self._temp_val = Label(name="dashboard-card-value", label="—", h_align="center")
        self._disk_val = Label(name="dashboard-card-value", label="—", h_align="center")

        stats_row = Box(
            name="dashboard-stats",
            orientation="h",
            spacing=8,
            children=[
                _stat_card("cpu-symbolic",          self._cpu_val,  "CPU"),
                _stat_card("ram-symbolic",          self._ram_val,  "RAM"),
                _stat_card("sensors-temperature-symbolic", self._temp_val, "TEMP"),
                _stat_card("drive-harddisk-symbolic", self._disk_val, "DISK"),
            ],
        )

        Fabricator(
            interval=1000,
            poll_from=lambda *_: psutil.cpu_percent(),
            on_changed=lambda _, v: self._cpu_val.set_label(f"{int(v)}%"),
        )
        Fabricator(
            interval=2000,
            poll_from=lambda *_: psutil.virtual_memory().percent,
            on_changed=lambda _, v: self._ram_val.set_label(f"{int(v)}%"),
        )
        Fabricator(
            interval=3000,
            poll_from=lambda *_: _get_cpu_temp(),
            on_changed=lambda _, v: self._temp_val.set_label(v),
        )
        Fabricator(
            interval=10000,
            poll_from=lambda *_: _get_disk_percent(),
            on_changed=lambda _, v: self._disk_val.set_label(f"{v}%"),
        )

        # ── Weather ──────────────────────────────────────────────────────
        self._weather_label = Label(
            name="dashboard-weather-text",
            label="updating…",
            h_align="start",
            h_expand=True,
        )
        weather_card = Box(
            name="dashboard-weather-card",
            orientation="h",
            spacing=12,
            children=[
                Image(icon_name="weather-few-clouds-symbolic", icon_size=32),
                self._weather_label,
            ],
        )

        # ── cmus ──────────────────────────────────────────────────────────────
        self._track_label = Label(
            name="dashboard-track",
            label="—",
            h_align="start",
            h_expand=True,
        )
        self._playpause_icon = Image(
            icon_name="media-playback-start-symbolic", icon_size=32,
        )

        def _cmus_btn(icon: str, cmd_args: list) -> Button:
            return Button(
                name="dashboard-cmus-btn",
                child=Image(icon_name=icon, icon_size=32),
                on_clicked=lambda *_: subprocess.run(
                    ["cmus-remote"] + cmd_args,
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                ),
            )

        # State: cmus running — track + controls
        self._cmus_controls_box = Box(
            orientation="h",
            spacing=10,
            h_expand=True,
            children=[
                self._track_label,
                Box(
                    name="dashboard-cmus-controls",
                    orientation="h",
                    spacing=2,
                    children=[
                        _cmus_btn("media-skip-backward-symbolic", ["-r"]),
                        Button(
                            name="dashboard-cmus-btn",
                            child=self._playpause_icon,
                            on_clicked=lambda *_: subprocess.run(
                                ["cmus-remote", "-u"],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                            ),
                        ),
                        _cmus_btn("media-skip-forward-symbolic", ["-n"]),
                    ],
                ),
            ],
        )

        # State: cmus stopped — headless start button
        self._cmus_start_box = Box(
            orientation="h",
            spacing=10,
            h_expand=True,
            children=[
                Button(
                    name="dashboard-cmus-btn",
                    child=Box(
                        orientation="h",
                        spacing=8,
                        children=[
                            Image(icon_name="media-playback-start-symbolic", icon_size=32),
                            Label(label="Start cmus", h_align="start"),
                        ],
                    ),
                    on_clicked=lambda *_: _start_cmus_headless(),
                ),
            ],
        )

        _init_running, _, _ = _cmus_status()
        self._cmus_controls_box.set_visible(_init_running)
        self._cmus_start_box.set_visible(not _init_running)

        cmus_row = Box(
            name="dashboard-cmus",
            orientation="h",
            spacing=10,
            children=[
                Image(name="dashboard-cmus-icon",
                      icon_name="audio-x-generic-symbolic", icon_size=32),
                self._cmus_controls_box,
                self._cmus_start_box,
            ],
        )

        Fabricator(
            interval=2000,
            poll_from=lambda *_: _cmus_status(),
            on_changed=self._on_cmus_update,
        )

        # ── nmtui ─────────────────────────────────────────────────────────────
        _net_icon_init, _net_label_init = _get_net_status()
        self._net_icon = Image(icon_name=_net_icon_init, icon_size=32)
        self._net_label = Label(label=_net_label_init, h_align="start", h_expand=True)

        net_btn = Button(
            name="dashboard-net-btn",
            child=Box(
                orientation="h",
                spacing=10,
                children=[self._net_icon, self._net_label],
            ),
            on_clicked=lambda *_: (self.set_visible(False), _launch_nmtui()),
        )

        Fabricator(
            interval=5000,
            poll_from=lambda *_: _get_net_status(),
            on_changed=self._on_net_update,
        )

        # ── Session ──────────────────────────────────────────────────
        def _session_btn(icon: str, label: str, action) -> Button:
            btn = Button(
                name="dashboard-session-btn",
                child=Box(
                    orientation="v",
                    spacing=4,
                    h_align="center",
                    children=[
                        Image(icon_name=icon, icon_size=32),
                        Label(name="dashboard-session-label",
                              label=label, h_align="center"),
                    ],
                ),
                on_clicked=lambda *_, a=action: (self.set_visible(False), a()),
            )
            btn.set_hexpand(True)
            return btn

        session_row = Box(
            name="dashboard-session",
            orientation="h",
            spacing=8,
            children=[
                _session_btn("system-lock-screen-symbolic", "Lock",      on_lock or session_actions.lock),
                _session_btn("system-log-out-symbolic",     "Log Out",   session_actions.logout),
                _session_btn("system-reboot-symbolic",      "Reboot",    session_actions.reboot),
                _session_btn("system-shutdown-symbolic",    "Power Off", session_actions.poweroff),
            ],
        )

        # ── Main layout ───────────────────────────────────────────────────────
        self.add(
            Box(
                name="info-dashboard",
                orientation="v",
                spacing=10,
                children=[stats_row, weather_card, cmus_row, net_btn, session_row],
            )
        )

        self.add_keybinding("escape", lambda *_: self.set_visible(False))
        self.show_all()

    def _on_net_update(self, _, value):
        icon_name, label_text = value
        self._net_icon.set_from_icon_name(icon_name, 32)
        self._net_label.set_label(label_text)

    def _on_cmus_update(self, _, value):
        running, status, track = value
        self._cmus_controls_box.set_visible(running)
        self._cmus_start_box.set_visible(not running)
        if running:
            self._track_label.set_label(track)
            icon = (
                "media-playback-pause-symbolic"
                if status == "playing"
                else "media-playback-start-symbolic"
            )
            self._playpause_icon.set_from_icon_name(icon, 32)

    def toggle(self):
        if self.get_visible():
            self.set_visible(False)
        else:
            self._weather_label.set_label("loading…")
            self.show_all()
            self.set_visible(True)
            threading.Thread(target=self._load_weather, daemon=True).start()

    def _load_weather(self):
        result = _fetch_weather_sync()
        GLib.idle_add(self._weather_label.set_label, result)
