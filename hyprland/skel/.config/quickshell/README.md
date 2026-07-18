# quickshell-d77

d77-shell is a simple QT desktop shell built on top of Quickshell. It is designed to be compositor-agnostic across Wayland compositors, with native integrations for Hyprland, Sway, and niri.

> **Note on i3**: every surface in this shell (bar, launcher, dashboard, lockscreen, wallpaper picker) is a Wayland layer-shell client (`PanelWindow`/`WlrLayershell`, `WlSessionLock`). i3 is an X11-only window manager with no Wayland compositor, so it cannot host any of these windows — there is no i3 support, and there cannot be one without rewriting the shell's window layer for X11.

![sample](sample.png)

To install:

1 - Clone the Repository

```
git clone https://github.com/dani-77/quickshell-d77.git ~/.config/quickshell
```

2 - Execute the shell

```
qs -p ~/.config/quickshell/shell.qml
```

## Compositor-Agnostic & Workspaces

The shell automatically detects the running Wayland compositor (`Hyprland`, `Sway`, `niri`, or others) at startup:
- **Hyprland**: Dynamically loads a workspace widget reading `Hyprland.workspaces` and using `hyprctl` for workspace switching. Fixed 1-9 grid.
- **Sway**: Dynamically loads a workspace widget reading `I3.workspaces` (Sway implements the i3 IPC protocol) and using `swaymsg` to switch workspaces. Fixed 1-9 grid.
- **niri**: detected via `$NIRI_SOCKET`. Dynamically loads a workspace widget reading `Quickshell.WindowManager` (the generic `ext-workspace-v1` protocol niri implements — no dedicated Quickshell module needed, and no IPC polling either, since it's reactive out of the box). Unlike Hyprland/Sway, this does **not** show a fixed 1-9 grid: niri creates workspaces dynamically instead of preallocating a fixed set, so only the workspaces that actually exist are shown, and switching calls the workspace object's own `activate()` method rather than shelling out to a CLI.
- **Generic/Other**: Falls back gracefully by omitting the workspace widget, keeping the bar clean.

The logout process also dynamically chooses between `hyprctl dispatch exit`, `swaymsg exit`, `niri msg action quit --skip-confirmation`, or standard login1 session termination (`loginctl terminate-session`) as a last resort.

## Session actions (suspend/reboot/poweroff/logout)

Both the **dashboard** and the **session menu** trigger the same underlying processes for suspend, reboot, poweroff and logout. These go through the freedesktop **login1** D-Bus interface via `loginctl`, which works identically whether it's backed by:
- **systemd-logind** — the default on systemd distros (e.g. **Arch**), or
- **elogind** — the standalone logind fork used on non-systemd distros with a Wayland desktop (e.g. **Void**).

No compositor- or distro-specific branching is needed for this: as long as one of the two is running (which any Wayland session with `polkit`/seat management typically already requires), `loginctl suspend/reboot/poweroff` work unmodified. As a second attempt, `systemctl <action>` is also tried for the rare case where `loginctl` isn't on `PATH` but systemd is.

**Why niri gets a native logout instead of going through loginctl**: `niri-session` runs niri as a **systemd `--user` service** and waits on it. Killing the login1 session from the outside (`loginctl terminate-session`) detaches the display but leaves `niri.service` marked active, so the *next* login's `niri-session` refuses to start ("niri session is already running") — a [known niri issue](https://github.com/niri-wm/niri/discussions/2729). Quitting niri natively via IPC lets its own service wrapper notice the exit and clean up `niri.service` correctly, so the shell does that instead of touching logind at all for niri.

**Logout and `$XDG_SESSION_ID`** (the true generic case — no native exit dispatcher, e.g. river, wayfire, labwc): `loginctl terminate-session` targets `$XDG_SESSION_ID` if it's set in the environment, falling back to the `self` magic session ID otherwise. This matters because `self` resolves the caller's session by looking up its PID's cgroup, which fails with `Failed to issue method call: Caller does not belong to any known session.` when the compositor runs as a systemd `--user` service — e.g. Hyprland launched via **UWSM**. In that setup the shell's process lives under `user@<uid>.service` rather than the login `session-N.scope`, so logind can't map "self" back to a session — but these session managers import `$XDG_SESSION_ID` into the environment specifically so tools like this can target the session explicitly instead.

If nothing succeeds, the failure isn't silent: a small red toast appears at the top of the screen for a few seconds with the actual command output (e.g. the `Caller does not belong to...` message above), instead of the button silently doing nothing.

## Native application launcher

The shell ships with a built-in application launcher (Rofi/Fuzzel style), written entirely in QML — no external dependencies. It is already wired into `shell.qml`:

- Click the purple launcher button on the left of the bar, **or**
- Trigger it via a window manager keybind calling the IPC (see below).

Detailed module documentation lives in [`launcher/README.md`](launcher/README.md).

## Native lockscreen

The shell also bundles a native **lockscreen** module (folder `lockscreen/`, adapted from [quickshell-examples](https://github.com/quickshell-mirror/quickshell-examples)), written entirely in QML and themed to match the rest of the shell (Tokyo Night). It uses a real `WlSessionLock` and validates the password through **PAM**, so the screen stays genuinely locked until a valid password is typed.

- Lock it from the **session menu** (the "Lock" entry), **or**
- Trigger it via a window manager keybind calling the IPC (see below, suggested `SUPER + L`).

Detailed module documentation lives in [`lockscreen/README.md`](lockscreen/README.md).

## Native greeter (login screen)

The shell also bundles a native **greeter** for [greetd](https://github.com/kennylevinsen/greetd) (folder `greeter/`), inspired by [DankMaterialShell's Greetd module](https://github.com/AvengeMedia/DankMaterialShell/tree/master/quickshell/Modules/Greetd) but trimmed down and adapted to quickshell-d77: same Tokyo Night styling as the lockscreen, and the same QML-drawn `Backdrop` background as the rest of the shell instead of a synced wallpaper image.

It scans both `/usr/share/wayland-sessions` and `/usr/share/xsessions` (X11) for available sessions, and launches whichever one is picked through greetd's IPC — X11 sessions are wrapped with `startx` automatically, since greetd doesn't start an Xorg server on its own.

The greeter itself needs a Wayland compositor to run under before any user session exists; wrapper scripts ship for **Hyprland**, **niri**, **Sway**, and **mangowc** (`greeter/assets/greet-{hyprland,niri,sway,mango}.sh`) — pick whichever you have installed. All four have been verified to load the greeter cleanly (nested, no QML warnings).

Unlike the other modules above, the greeter replaces your display manager and needs system-level setup (a `greeter` user, `/etc/greetd/config.toml`, disabling gdm/sddm/lightdm). See [`greeter/README.md`](greeter/README.md) for the full installation steps.

## Native OSD (volume & brightness)

The shell also bundles a native **OSD** module (folder `osd/`, adapted from [quickshell-examples → volume-osd](https://github.com/quickshell-mirror/quickshell-examples/tree/master/volume-osd)). A minimalist overlay (icon + progress bar + value) pops up in the **top-right corner** whenever the volume or screen brightness changes, and fades out after ~2.5 s.

- **Volume** uses the **ALSA** backend (`amixer`) with **mute/unmute** support.
- **Brightness** uses **brightnessctl**.

Trigger it from your media keys via IPC (see below). A background watcher also catches *external* changes (e.g. another app changing the volume) and shows the OSD anyway.

Detailed module documentation lives in [`osd/README.md`](osd/README.md).

## Compositor-Agnostic Wallpaper Chooser

The shell features a built-in Wallpaper selector written in QML. Under the hood, it delegates all tasks to a helper script `set-wallpaper.sh`, making it fully compositor-agnostic:
- **Hyprland**: Applies wallpapers via `hyprctl hyprpaper` (with automated preloading).
- **Sway**: Applies wallpapers natively via `swaymsg output`.
- **Other Compositors**: Automatically falls back to popular tools like `swww`, `swaybg`, or `feh` depending on which ones are installed.

It is automatically triggered from the wallpaper menu or via IPC.

**Restoring the wallpaper at login** works differently per compositor, since only Hyprland's hyprpaper supports a config-file preload step:
- **Hyprland**: `apply-saved-wallpaper.sh` rewrites `hyprpaper.conf` *before* hyprpaper starts, so it launches already showing the right wallpaper. Run it from `hyprland.conf` before `exec-once = hyprpaper` (see the script's header for details).
- **Sway / generic**: there's no preload step, so add `set-wallpaper.sh startup` as an `exec` line in your compositor's config, after the compositor itself has started. It reads the saved path from the state file and reapplies it — a brief default background may flash before this runs.

```text
# ~/.config/sway/config
exec ~/.config/quickshell/wallpaper/set-wallpaper.sh startup
```

## Hyprland-Only Features

While all shell widgets, the launcher, lockscreen, and OSD are fully compatible across Wayland compositors, some integrations are exclusive to **Hyprland**:

1. **Global Shortcuts Fallback (`GlobalShortcut` in QML)**:
   The native `GlobalShortcut` bindings in QML rely on Hyprland's global shortcuts Wayland protocol. They are disabled on Sway and other compositors. On those compositors, you must configure keybinds in your WM config file (e.g. `~/.config/sway/config`) calling the Quickshell IPC directly.
2. **Hyprland Workspace Dispatching**:
   The custom workspace dispatch options using `hyprctl` only apply when running under Hyprland. Sway uses native workspace focusing commands (`swaymsg workspace`).

---

## Controlling the shell via IPC (recommended)

`shell.qml` exposes three Quickshell `IpcHandler` targets so the launcher, the session menu and the lockscreen can be triggered from anywhere while the shell is running:

| Target       | Functions                 | What it does                              |
|--------------|---------------------------|-------------------------------------------|
| `launcher`   | `toggle`, `open`, `close` | Show/hide the application launcher        |
| `session`    | `toggle`, `open`, `close` | Show/hide the session menu (lock/suspend/reboot/shutdown/logout) |
| `wallpaper`  | `toggle`, `open`, `close`  | Show/hide the wallpaper menu               |
| `lockscreen` | `lock`, `unlock`, `toggle` | Lock the screen (PAM) / unlock / alternate |
| `osd`        | `volumeUp`, `volumeDown`, `volumeMuteToggle`, `brightnessUp`, `brightnessDown`, `showVolume`, `showBrightness` | Volume (ALSA, with mute) & brightness (brightnessctl) OSD |

Call them from the command line:

```bash
qs ipc call launcher toggle     # toggle the launcher
qs ipc call launcher open       # open the launcher
qs ipc call launcher close      # close the launcher

qs ipc call session toggle      # toggle the session menu
qs ipc call session open        # open the session menu
qs ipc call session close       # close the session menu

qs ipc call lockscreen lock     # lock the screen (asks for password via PAM)
qs ipc call lockscreen unlock   # unlock without a password
qs ipc call lockscreen toggle   # alternate locked/unlocked

qs ipc call wallpaper toggle     # toggle the wallpaper menu
qs ipc call wallpaper open       # open the wallpaper menu
qs ipc call wallpaper close      # close the wallpaper menu

qs ipc call osd volumeUp           # volume +5% (shows the OSD)
qs ipc call osd volumeDown         # volume -5%
qs ipc call osd volumeMuteToggle   # mute / unmute
qs ipc call osd brightnessUp       # brightness +5%
qs ipc call osd brightnessDown     # brightness -5%

qs ipc show                     # list every target/function exposed
```

### OSD keybinds (media keys)

Bind your media keys in your window manager configuration:

#### Hyprland (`hyprland.conf`)
```ini
bindel = , XF86AudioRaiseVolume,  exec, qs ipc call osd volumeUp
bindel = , XF86AudioLowerVolume,  exec, qs ipc call osd volumeDown
bindl  = , XF86AudioMute,         exec, qs ipc call osd volumeMuteToggle
bindel = , XF86MonBrightnessUp,   exec, qs ipc call osd brightnessUp
bindel = , XF86MonBrightnessDown, exec, qs ipc call osd brightnessDown
```

#### Sway (`~/.config/sway/config`)
```text
bindsym --locked XF86AudioRaiseVolume  exec qs ipc call osd volumeUp
bindsym --locked XF86AudioLowerVolume  exec qs ipc call osd volumeDown
bindsym --locked XF86AudioMute         exec qs ipc call osd volumeMuteToggle
bindsym --locked XF86MonBrightnessUp   exec qs ipc call osd brightnessUp
bindsym --locked XF86MonBrightnessDown exec qs ipc call osd brightnessDown
```

### Window Manager keybinds (IPC)

This is the recommended way to bind the shell:

#### Hyprland (`hyprland.conf`)
```ini
bind = SUPER, D, exec, qs ipc call launcher toggle      # application launcher
bind = SUPER SHIFT, E, exec, qs ipc call session toggle # session menu
bind = SUPER, L, exec, qs ipc call lockscreen lock      # lock the screen
bind = SUPER, Y, exec, qs ipc call wallpaper toggle     # wallpaper menu
```

#### Sway (`~/.config/sway/config`)
```text
bindsym $mod+d exec qs ipc call launcher toggle
bindsym $mod+Shift+e exec qs ipc call session toggle
bindsym $mod+l exec qs ipc call lockscreen lock
bindsym $mod+y exec qs ipc call wallpaper toggle
```

> 📖 Full **Hyprland** keybind setup — including **Hyprland with Lua** (generating `hyprland.conf`, `init.lua`, `hyprctl keyword`, `source`) and how to verify the IPC targets (`qs ipc show`) — is in [`KEYBINDS.md`](KEYBINDS.md). That guide is Hyprland-specific; for Sway, the snippets above are the full picture.

### Global shortcuts fallback (Hyprland only)

`shell.qml` also registers three Quickshell `GlobalShortcut`s (`launcher`, `session` and `lock`) as a fallback (exclusive to Hyprland). To use them instead of IPC:

```ini
bind = SUPER, D, global, quickshell:launcher      # application launcher
bind = SUPER SHIFT, E, global, quickshell:session # session menu
bind = SUPER, L, global, quickshell:lock          # lock the screen
bind = SUPER, Y, global, quickshell:wallpaper     # wallpaper menu
```

The format is `<appid>:<name>` (default `appid` is `quickshell`). See [`KEYBINDS.md`](KEYBINDS.md) for details.

### Launcher keybindings

| Key                | Action                          |
|--------------------|---------------------------------|
| Type               | Filter the application list     |
| `↑` / `↓`          | Move the selection              |
| `Tab`              | Next item                       |
| `Enter`            | Launch the selected application |
| `Esc` / click out  | Close the launcher              |

### Lockscreen keybindings

| Key        | Action                                   |
|------------|------------------------------------------|
| Type       | Enter your password                      |
| `Enter`    | Submit and try to unlock (via PAM)       |
| Click `Unlock` | Submit and try to unlock             |

Enjoy
