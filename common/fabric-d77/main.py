import os
import sys
import signal

from fabric import Application
from fabric.widgets.button import Button
from fabric.widgets.image import Image
from fabric.utils import get_relative_path

from bar import StatusBar
from launcher import AppLauncher
from session_menu import SessionMenu
from osd import OSD
from wallpaper_selector import WallpaperSelector
from dashboard import InfoDashboard
from backdrop import Backdrop
from lockscreen import LockScreen

class MainStatusBar(StatusBar):
    def __init__(self, launcher_window: AppLauncher, wallpaper_selector: WallpaperSelector, session_menu: SessionMenu, osd: OSD):
        self.launcher = launcher_window
        self.wallpaper_selector = wallpaper_selector
        self.session_menu = session_menu
        super().__init__(osd=osd)

    def show_all(self):
        launcher_button = Button(
            name="launcher-button",
            child=Image(icon_name="view-app-grid-symbolic", icon_size=14),
            on_clicked=lambda *_: self.toggle_launcher(),
        )

        wallpaper_button = Button(
            name="wallpaper-button",
            child=Image(icon_name="preferences-desktop-wallpaper-symbolic", icon_size=14),
            on_clicked=lambda *_: self.toggle_wallpaper_selector(),
        )

        current_left = list(self.left_container.children)
        current_left.insert(0, launcher_button)
        current_left.insert(1, wallpaper_button)
        self.left_container.children = current_left

        self.power_button = Button(
            name="power-button",
            child=Image(icon_name="system-shutdown-symbolic", icon_size=14),
            on_clicked=lambda btn: self.popup_power_menu(btn),
        )

        self.right_container.add(self.power_button)

        return super().show_all()

    def toggle_wallpaper_selector(self):
        self.wallpaper_selector.toggle()

    def popup_power_menu(self, button=None):
        # The session menu is a layer-shell window anchored to the center of the
        # screen (see session_menu.SessionMenu), so it always opens centered
        # regardless of where the power button lives on the bar.
        self.session_menu.toggle()

    def toggle_launcher(self):
        if self.launcher.get_visible():
            self.launcher.set_visible(False)
        else:
            self.launcher.show_all()
            self.launcher.refresh_apps()
            self.launcher.set_visible(True)
            self.launcher.search_entry.grab_focus()


if __name__ == "__main__":
    # Decorative background shown only while no wallpaper is active (see
    # backdrop.py). Reacts to state file changes on its own
    # (wallpaper_state.py) — no extra wiring needed here.
    backdrop = Backdrop()

    launcher = AppLauncher()
    launcher.set_visible(False)
    launcher.add_keybinding("escape", lambda: launcher.set_visible(False))

    # Native locker (ext-session-lock-v1 via GtkSessionLock), with automatic
    # fallback to swaylock/hyprlock/loginctl (session_actions.lock) if the
    # protocol or PAM are unavailable — see lockscreen.py.
    lockscreen = LockScreen()

    session_menu = SessionMenu(on_lock=lockscreen.lock)
    session_menu.set_visible(False)

    wallpaper_selector = WallpaperSelector()
    wallpaper_selector.set_visible(False)
    wallpaper_selector.add_keybinding("escape", lambda: wallpaper_selector.set_visible(False))


    # OSD overlay (volume + brightness). Shows itself on detected changes
    # (polling), so it works even if media keys are wired directly to
    # amixer/brightnessctl.
    osd = OSD()

    dashboard = InfoDashboard(on_lock=lockscreen.lock)
    dashboard.set_visible(False)

    bar = MainStatusBar(launcher_window=launcher, session_menu=session_menu, wallpaper_selector=wallpaper_selector, osd=osd)
    app = Application("d77-shell", bar, launcher, session_menu, osd, wallpaper_selector, dashboard, backdrop)

    signal.signal(signal.SIGUSR1, lambda signum, frame: bar.toggle_launcher())
    signal.signal(signal.SIGUSR2, lambda signum, frame: bar.popup_power_menu())

    # Real-time signals to trigger the OSD from keybinds, if you prefer
    # the shell to apply the change (alternative to wiring keys
    # directly to amixer/brightnessctl):
    #   SIGRTMIN+1  volume +        SIGRTMIN+4  brightness +      SIGRTMIN+7  dashboard
    #   SIGRTMIN+2  volume -        SIGRTMIN+5  brightness -      SIGRTMIN+8  lock
    #   SIGRTMIN+3  mute toggle     SIGRTMIN+6  wallpaper picker
    # Example (Hyprland):
    #   bindel = , XF86AudioRaiseVolume, exec, kill -s SIGRTMIN+1 $(pgrep -f main.py)
    rtmin = signal.SIGRTMIN
    signal.signal(rtmin + 1, lambda s, f: osd.volume_up())
    signal.signal(rtmin + 2, lambda s, f: osd.volume_down())
    signal.signal(rtmin + 3, lambda s, f: osd.volume_mute_toggle())
    signal.signal(rtmin + 4, lambda s, f: osd.brightness_up())
    signal.signal(rtmin + 5, lambda s, f: osd.brightness_down())
    signal.signal(rtmin + 6, lambda s, f: bar.toggle_wallpaper_selector())
    signal.signal(rtmin + 7, lambda s, f: dashboard.toggle())
    signal.signal(rtmin + 8, lambda s, f: lockscreen.lock())

    style_path = get_relative_path("./style.css")
    if os.path.exists(style_path):
        app.set_stylesheet_from_file(style_path)

    app.run()
