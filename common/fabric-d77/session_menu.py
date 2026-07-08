import session_actions

from fabric.widgets.box import Box
from fabric.widgets.label import Label
from fabric.widgets.button import Button
from fabric.widgets.image import Image
from fabric.widgets.wayland import WaylandWindow as Window


class SessionMenu(Window):
    """Power / session menu rendered as a layer-shell window centered on screen."""

    def __init__(self, on_lock=None, **kwargs):
        super().__init__(
            layer="overlay",
            anchor="center",
            exclusivity="none",
            keyboard_mode="on-demand",
            visible=False,
            all_visible=False,
            **kwargs,
        )

        self.add(
            Box(
                name="session-menu",
                orientation="v",
                spacing=4,
                children=[
                    self.bake_item("Lock",      "system-lock-screen-symbolic", on_lock or session_actions.lock),
                    self.bake_item("Log Out",   "system-log-out-symbolic",     session_actions.logout),
                    self.bake_item("Reboot",    "system-reboot-symbolic",      session_actions.reboot),
                    self.bake_item("Power Off", "system-shutdown-symbolic",    session_actions.poweroff),
                ],
            )
        )

        self.add_keybinding("escape", lambda *_: self.set_visible(False))
        self.show_all()

    def bake_item(self, label_text: str, icon_name: str, action) -> Button:
        return Button(
            child=Box(
                orientation="h",
                spacing=12,
                children=[
                    Image(icon_name=icon_name, icon_size=32),
                    Label(label=label_text, h_align="start"),
                ],
            ),
            on_clicked=lambda *_: (self.set_visible(False), action()),
        )

    def toggle(self):
        if self.get_visible():
            self.set_visible(False)
        else:
            self.show_all()
            self.set_visible(True)
