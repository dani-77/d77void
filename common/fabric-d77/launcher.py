from terminal_launcher import launch_app
import operator
import os
from collections.abc import Iterator
from gi.repository import GdkPixbuf, Gio
from fabric import Application
from fabric.widgets.box import Box
from fabric.widgets.label import Label
from fabric.widgets.button import Button
from fabric.widgets.image import Image
from fabric.widgets.entry import Entry
from fabric.widgets.scrolledwindow import ScrolledWindow
from fabric.widgets.wayland import WaylandWindow as Window
from fabric.utils import DesktopApp, get_desktop_applications, idle_add, remove_handler


def _get_icon_pixbuf(app: DesktopApp, size: int = 32):
    icon_path = getattr(app, "icon_name", None)
    if icon_path and os.path.isabs(icon_path) and os.path.isfile(icon_path):
        try:
            return GdkPixbuf.Pixbuf.new_from_file_at_scale(icon_path, size, size, True)
        except Exception:
            pass
    return app.get_icon_pixbuf(size=size, default_icon="application-x-executable")


class AppLauncher(Window):
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
        self._all_apps = get_desktop_applications()
        self._app_monitors = []
        for path in self._watched_app_dirs():
            gfile = Gio.File.new_for_path(path)
            mon = gfile.monitor_directory(Gio.FileMonitorFlags.NONE, None)
            mon.connect("changed", self._on_app_dir_changed)
            self._app_monitors.append(mon)

        self.viewport = Box(spacing=2, orientation="v")
        self.search_entry = Entry(
            placeholder="Search Applications...",
            h_expand=True,
            notify_text=lambda entry, *_: self.arrange_viewport(entry.get_text()),
        )
        self.scrolled_window = ScrolledWindow(
            min_content_size=(280, 320),
            max_content_size=(280 * 2, 320),
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
        self.add_keybinding("escape", lambda: self.set_visible(False))
        self.show_all()

    def _watched_app_dirs(self):
        candidates = [
            "/usr/share/applications",
            "/usr/local/share/applications",
            os.path.expanduser("~/.local/share/applications"),
        ]
        return [d for d in candidates if os.path.isdir(d)]

    def _on_app_dir_changed(self, monitor, file, _other, event_type):
        if file.get_basename().endswith(".desktop"):
            self._all_apps = get_desktop_applications()

    def refresh_apps(self):
        self.search_entry.set_text("")
        self.arrange_viewport("")

    def arrange_viewport(self, query: str = ""):
        remove_handler(self._arranger_handler) if self._arranger_handler else None
        self.viewport.children = []

        filtered_apps_iter = iter(
            [
                app
                for app in self._all_apps
                if query.casefold()
                in (
                    (app.display_name or "")
                    + (" " + app.name + " ")
                    + (app.generic_name or "")
                ).casefold()
            ]
        )
        should_resize = operator.length_hint(filtered_apps_iter) == len(self._all_apps)

        self._arranger_handler = idle_add(
            lambda *args: self.add_next_application(*args)
            or (self.resize_viewport() if should_resize else False),
            filtered_apps_iter,
            pin=True,
        )
        return False

    def add_next_application(self, apps_iter: Iterator[DesktopApp]):
        if not (app := next(apps_iter, None)):
            return False

        self.viewport.add(self.bake_application_slot(app))
        return True

    def resize_viewport(self):
        self.scrolled_window.set_min_content_width(
            self.viewport.get_allocation().width  # type: ignore
        )
        return False

    def bake_application_slot(self, app: DesktopApp, **kwargs) -> Button:
        return Button(
            child=Box(
                orientation="h",
                spacing=12,
                children=[
                    Image(pixbuf=_get_icon_pixbuf(app), h_align="start", size=32),
                    Label(
                        label=app.display_name or "Unknown",
                        v_align="center",
                        h_align="center",
                    ),
                ],
            ),
            tooltip_text=app.description,
	    on_clicked=lambda *_: (launch_app(app), self.set_visible(False)),
            **kwargs,
        )


if __name__ == "__main__":
    app_launcher = AppLauncher()
    app = Application("app-launcher", app_launcher)
    app.run()

