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

class MainStatusBar(StatusBar):
    def __init__(self, launcher_window: AppLauncher, wallpaper_selector: WallpaperSelector, session_menu: SessionMenu):
        self.launcher = launcher_window
        self.wallpaper_selector = wallpaper_selector
        self.session_menu = session_menu
        super().__init__()

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
    launcher = AppLauncher()
    launcher.set_visible(False)
    launcher.add_keybinding("escape", lambda: launcher.set_visible(False))

    session_menu = SessionMenu()
    session_menu.set_visible(False)

    wallpaper_selector = WallpaperSelector()
    wallpaper_selector.set_visible(False)
    wallpaper_selector.add_keybinding("escape", lambda: wallpaper_selector.set_visible(False))


    # OSD overlay (volume + brilho). Mostra-se sozinho ao detetar mudanças
    # (polling), por isso funciona mesmo que as teclas multimédia estejam
    # ligadas diretamente ao amixer/brightnessctl.
    osd = OSD()

    dashboard = InfoDashboard()
    dashboard.set_visible(False)

    bar = MainStatusBar(launcher_window=launcher, session_menu=session_menu, wallpaper_selector=wallpaper_selector)
    app = Application("d77-shell", bar, launcher, session_menu, osd, wallpaper_selector, dashboard)

    signal.signal(signal.SIGUSR1, lambda signum, frame: bar.toggle_launcher())
    signal.signal(signal.SIGUSR2, lambda signum, frame: bar.popup_power_menu())

    # Sinais em tempo real para acionar o OSD a partir de keybinds, caso se
    # prefira que seja a shell a aplicar a alteração (alternativa a ligar as
    # teclas diretamente ao amixer/brightnessctl):
    #   SIGRTMIN+1  volume +        SIGRTMIN+4  brilho +
    #   SIGRTMIN+2  volume -        SIGRTMIN+5  brilho -
    #   SIGRTMIN+3  mute toggle
    # Ex. (Hyprland):
    #   bindel = , XF86AudioRaiseVolume, exec, kill -s SIGRTMIN+1 $(pgrep -f main.py)
    rtmin = signal.SIGRTMIN
    signal.signal(rtmin + 1, lambda s, f: osd.volume_up())
    signal.signal(rtmin + 2, lambda s, f: osd.volume_down())
    signal.signal(rtmin + 3, lambda s, f: osd.volume_mute_toggle())
    signal.signal(rtmin + 4, lambda s, f: osd.brightness_up())
    signal.signal(rtmin + 5, lambda s, f: osd.brightness_down())
    signal.signal(rtmin + 6, lambda s, f: bar.toggle_wallpaper_selector())
    signal.signal(rtmin + 7, lambda s, f: dashboard.toggle())
    
    style_path = get_relative_path("./style.css")
    if os.path.exists(style_path):
        app.set_stylesheet_from_file(style_path)

    app.run()
