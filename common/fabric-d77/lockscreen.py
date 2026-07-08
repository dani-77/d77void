"""Native screen locker for fabric-d77.

Unlike ``session_actions.lock()`` (which just shells out to swaylock /
hyprlock / loginctl), this module implements a *real* locker backed by the
``ext-session-lock-v1`` Wayland protocol via the GtkSessionLock library
(https://github.com/Cu3PO42/gtk-session-lock, the library gtklock is built
on). That means the compositor itself enforces the lock — not just a
fullscreen window on top — mirroring how the lockscreen was implemented in
quickshell-d77 (there via Quickshell's native WlSessionLock support).

Requirements:
  - The ``gtk-session-lock`` C library + GObject introspection typelib
    installed system-wide (build from source, or your distro's package —
    e.g. the AUR ``gtk-session-lock`` package on Arch). Not a pip package.
  - ``python-pam`` (already in requirements.txt) for password verification.
  - A PAM service file at /etc/pam.d/fabric-d77, e.g.:
        auth	include	system-auth
        account	include	system-auth
    (Debian/Ubuntu: replace "system-auth" with "common-auth"/"common-account".)
    Without it PAM fails closed (falls through to /etc/pam.d/other, which
    denies by default on most distros) — the lock screen stays up, it just
    can't be unlocked.

If the protocol isn't supported by the compositor, the library isn't
installed, or PAM isn't available, ``lock()`` transparently falls back to
``session_actions.lock()``.
"""

import getpass
import threading
from datetime import datetime

import gi

gi.require_version("Gtk", "3.0")
try:
    gi.require_version("GtkSessionLock", "0.1")
    from gi.repository import GtkSessionLock
    _HAS_SESSION_LOCK = True
except (ValueError, ImportError):
    _HAS_SESSION_LOCK = False

from gi.repository import Gdk, GLib, Gtk

try:
    import pam
    _HAS_PAM = True
except ImportError:
    _HAS_PAM = False

import session_actions
from fabric import Fabricator
from fabric.widgets.box import Box
from fabric.widgets.entry import Entry
from fabric.widgets.image import Image
from fabric.widgets.label import Label

PAM_SERVICE = "fabric-d77"


class LockScreen:
    """Owns at most one active session lock at a time."""

    def __init__(self):
        self._lock = None
        self._locked = False
        self._windows = []
        self._fabricators = []

    @property
    def supported(self) -> bool:
        return _HAS_SESSION_LOCK and _HAS_PAM and GtkSessionLock.is_supported()

    def lock(self, *_):
        if self._locked:
            return
        if not self.supported:
            session_actions.lock()
            return

        self._locked = True
        self._lock = GtkSessionLock.prepare_lock()
        self._lock.connect("finished", self._on_finished)
        self._lock.lock_lock()

        display = Gdk.Display.get_default()
        self._windows = []
        for i in range(display.get_n_monitors()):
            monitor = display.get_monitor(i)
            window = self._build_surface()
            self._lock.new_surface(window, monitor)
            window.show_all()
            self._windows.append(window)

    def _build_surface(self) -> Gtk.Window:
        window = Gtk.Window()
        window.get_style_context().add_class("lock-screen")

        clock_label = Label(name="lock-clock")

        # Keep a reference so we can stop it on unlock — without this the
        # Fabricator keeps firing after the window is destroyed and corrupts
        # the GTK main loop.
        fab = Fabricator(
            interval=1000,
            poll_from=lambda f: datetime.now().strftime("%H:%M"),
            on_changed=lambda _, value: clock_label.set_label(value),
        )
        self._fabricators.append(fab)

        status_label = Label(name="lock-status", label="")

        entry = Entry(
            name="lock-entry",
            placeholder="Password",
            password=True,
            h_align="center",
        )
        entry.connect("activate", lambda *_: self._try_unlock(entry, status_label))

        window.add(
            Box(
                orientation="v",
                spacing=16,
                h_align="center",
                v_align="center",
                children=[
                    Image(icon_name="system-lock-screen-symbolic", icon_size=48),
                    clock_label,
                    entry,
                    status_label,
                ],
            )
        )
        window.connect("map", lambda *_: entry.grab_focus())
        return window

    def _try_unlock(self, entry: Entry, status_label: Label):
        password = entry.get_text()
        entry.set_text("")
        entry.set_sensitive(False)
        status_label.set_label("Checking…")
        username = getpass.getuser()

        def worker():
            ok = pam.pam().authenticate(username, password, service=PAM_SERVICE)
            GLib.idle_add(self._on_auth_result, entry, status_label, ok)

        threading.Thread(target=worker, daemon=True).start()

    def _on_auth_result(self, entry: Entry, status_label: Label, ok: bool) -> bool:
        if ok:
            self._unlock()
        else:
            status_label.set_label("Wrong password")
            entry.set_sensitive(True)
            entry.grab_focus()
        return False

    def _unlock(self):
        if self._lock is not None:
            lock, self._lock = self._lock, None
            lock.unlock_and_destroy()
        self._locked = False
        # Schedule destruction as an idle callback so the main loop can process
        # the compositor's unlock acknowledgment before we destroy the surfaces.
        # Calling display.sync() here deadlocks: the compositor may be waiting
        # for us to drain events while we block waiting for it.
        GLib.idle_add(self._destroy_windows)

    def _destroy_windows(self):
        for fab in self._fabricators:
            fab.stop()
        self._fabricators = []
        # Do NOT call window.destroy() — unlock_and_destroy() already freed the
        # Wayland lock surfaces at the protocol level; a second destroy triggers
        # a Wayland protocol error that kills the entire compositor client.
        # Dropping the Python references is enough; GLib will finalize them.
        self._windows.clear()

    def _on_finished(self, *_):
        # Compositor ended the lock (rejected or taken over by another client).
        # Only fall back to an external locker if WE didn't initiate the unlock
        # — if _unlock() already cleared _locked we're in a normal flow.
        falling_back = self._locked
        self._lock = None
        self._locked = False
        self._destroy_windows()
        if falling_back:
            session_actions.lock()
