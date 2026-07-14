# `greeter` Module

Native login greeter for [greetd](https://github.com/kennylevinsen/greetd), written entirely
in QML for quickshell-d77, styled to match the rest of the shell (Tokyo Night) and reusing the
same QML-drawn background as [`backdrop/Backdrop.qml`](../backdrop/Backdrop.qml) — no raster
wallpaper needed, no theme-sync system to keep alive.

`greeter/GreeterBackdrop.qml` is that same chevrons + d77 logo drawing, vendored as a local
copy rather than imported across directories: greetd points `qs -p` straight at this `greeter/`
folder, making it its own self-contained config root, and Quickshell doesn't resolve relative
imports that climb back out of that root at runtime (confirmed by actually running `qs -p
greeter/` — `import "../backdrop"` fails to load even though the file is right there on disk).
Since this folder is meant to be copied out to `/etc/greetd/...` standalone anyway (see
Installation below), keeping the artwork local avoids depending on the rest of the repo being
deployed alongside it. If you tweak the chevrons/logo in `backdrop/Backdrop.qml`, mirror the
change here too.

Authentication goes through **greetd's own IPC** (`Quickshell.Services.Greetd`), so PAM is
handled entirely by the `greetd` daemon (via `/etc/pam.d/greetd`) — this module never touches
passwords itself beyond forwarding what greetd asks for.

![sample](../sample.png)

## Features

- **Reads both X11 and Wayland sessions**: scans `/usr/share/wayland-sessions` and
  `/usr/share/xsessions` (plus `/usr/local/share/...`, every `XDG_DATA_DIRS` entry, and
  `~/.local/share/...`), parsing `Name=`/`Exec=` from each `.desktop` file.
- **Correct X11 launch**: greetd never starts an Xorg server on its own — it only execs the
  session command directly on the VT. Sessions found under an `xsessions` directory are
  therefore launched wrapped as `startx /usr/bin/env <Exec>` (the same default
  [tuigreet](https://github.com/apognu/tuigreet) uses for `--xsession-wrapper`), while sessions
  from `wayland-sessions` are exec'd as-is. `XDG_SESSION_TYPE` is set accordingly (`x11` vs
  `wayland`) instead of being hardcoded.
- **Same visual identity as the rest of the shell**: the background is `GreeterBackdrop`
  (chevrons + d77 logo, drawn in QML — the same artwork as `backdrop/Backdrop.qml`), and the
  login card follows the same Tokyo Night styling as `lockscreen/LockSurface.qml`.
- **Multi-monitor**: one surface per screen; only the primary screen is interactive/keyboard
  focused, the rest mirror the same background + state, same approach as the lockscreen.

## Module Contents

| File | Responsibility |
|------|-----------------|
| `Greeter.qml` | Session-directory scanner (X11 + Wayland), greetd IPC (`Quickshell.Services.Greetd`), per-screen `PanelWindow` variants. |
| `GreeterState.qml` | Shared singleton state: username, password, PAM feedback, discovered sessions. |
| `GreeterBackdrop.qml` | Vendored copy of the chevrons + d77 logo background (see note above). |
| `GreeterSurface.qml` | Per-monitor UI: `GreeterBackdrop`, clock, login card (username/password/session picker). |
| `shell.qml` | Standalone entry point — this is what greetd points `qs -p` at. |
| `assets/greet-dwl.sh` | Wrapper greetd runs: starts a disposable dwl instance hosting the greeter, quits it (via `SIGTERM`) once quickshell exits. |
| `greetd-config.toml.example` | Example `/etc/greetd/config.toml` pointing at `greet-dwl.sh`. |

## How It Works

```text
greetd (VT) ──runs──▶ greet-dwl.sh ──▶ disposable dwl instance ──▶ qs -p greeter/
                                                              │
                                                Greeter.qml ─┼─ scans xsessions/wayland-sessions
                                                              ├─ Quickshell.Services.Greetd (PAM via greetd)
                                                              └─ GreeterSurface (one per monitor)
```

1. `greetd` starts `greet-dwl.sh`, which launches a throwaway dwl instance whose only job is
   to host the greeter (`qs -p greeter/`).
2. `Greeter.qml` scans the session directories and populates `GreeterState` with every
   discovered session (name, exec command, and whether it's `x11` or `wayland`).
3. The user types a username/password and picks a session in the login card
   (`GreeterSurface.qml`), then presses **Login** (or Enter).
4. `Greeter.qml` calls `Greetd.createSession(username)`; when greetd/PAM asks for a response,
   the buffered password is sent back via `Greetd.respond(...)`.
5. On success (`onReadyToLaunch`), the selected session's `Exec=` command is launched — wrapped
   with `startx /usr/bin/env` first if it's an X11 session — and the host compositor is told to
   quit, handing the VT to the real session.
6. On failure, the password is cleared and "Incorrect username or password" is shown; the user
   can try again immediately.

## Installation

This module only covers the **QML greeter itself and its compositor wrapper**. Wiring it up as
your system's login manager touches system-wide files, so these steps are meant to be run
**manually, with root**, not automated:

1. Install `greetd` and `quickshell` from your distro's repositories.

2. Create the greeter system user (skip if your distro's `greetd` package already does this):
   ```bash
   sudo groupadd -r greeter
   sudo useradd -r -g greeter -d /var/lib/greeter -s /bin/bash -c "System Greeter" greeter
   sudo mkdir -p /var/lib/greeter
   sudo chown greeter:greeter /var/lib/greeter
   ```

3. Deploy this repo (or just the `greeter/` folder) somewhere the greeter user can read, and
   deploy the dwl wrapper:
   ```bash
   sudo mkdir -p /etc/greetd/quickshell-d77
   sudo cp -r ~/Projectos/quickshell-d77/greeter /etc/greetd/quickshell-d77/greeter

   sudo cp ~/Projectos/quickshell-d77/greeter/assets/greet-dwl.sh /etc/greetd/quickshell-d77/
   sudo chmod +x /etc/greetd/quickshell-d77/greet-dwl.sh
   ```
   `/usr/share/{xsessions,wayland-sessions}` are world-readable by default, so — unlike a
   wallpaper/theme-sync setup — no ACLs or group membership are needed just to list sessions.

4. Copy [`greetd-config.toml.example`](greetd-config.toml.example) to `/etc/greetd/config.toml`
   (back up the original first), adjusting `vt` if needed.

5. Disable your current display manager and enable `greetd`:
   ```bash
   sudo systemctl disable gdm sddm lightdm 2>/dev/null
   sudo systemctl enable greetd
   ```

6. Reboot (or `sudo systemctl start greetd` on a free VT) to try it.

### Testing without touching greetd

You can render the greeter UI directly under your *current* Wayland session — any compositor
implementing `zwlr_layer_shell_v1` works, not just dwl — to sanity-check the QML (it just won't
be able to complete a real login without a greetd socket to talk to):

```bash
qs -p ~/Projectos/quickshell-d77/greeter
```

`greet-dwl.sh` hasn't been run against a real dwl install as part of this repo's testing —
sanity-check it on your own machine before relying on it. dwl has no IPC socket to ask it to
quit and its `-s` startup command does not terminate dwl when it exits: dwl's `-s` command is
fork+execl'd directly with no setsid()/double-fork (see dwl.c's `run()`), so `$PPID` inside
that shell is dwl's own PID, and `greet-dwl.sh` sends it `SIGTERM` after `qs` exits — the same
thing dwl's own quit keybind does internally.

## Customization

Theme colors are passed the same way as the lockscreen — override them where `Greeter` is
instantiated:

```qml
Greeter {
    colBg:     "#1a1b26"
    colPurple: "#bb9af7"
    fsize:     13
}
```

`assets/greet-dwl.sh` is the host-compositor wrapper shipped out of the box, pointed at by
`greetd-config.toml`'s `command` line. To support a different compositor, copy it and adapt the
startup-command line and quit mechanism for that compositor's own syntax.

## Requirements

- **greetd**, with its PAM stack configured (`/etc/pam.d/greetd`, usually shipped by the
  greetd package).
- **Quickshell** with `Quickshell.Services.Greetd` support.
- **dwl**, to host the greeter itself before login (`assets/greet-dwl.sh`; see "Customization"
  above to swap in a different compositor).
- `startx`/`xinit` installed if you want X11 sessions to actually work — that's what
  X11 `Exec=` commands get wrapped with, since greetd doesn't start Xorg on its own.

## Known limitations

- No per-user avatar picker or multi-user list — this is deliberately a simple
  username/password/session form, consistent with the rest of quickshell-d77 (see the
  [lockscreen module](../lockscreen)). Nothing above stops you from adding one later.

## Remembering the last user/session

The username and session picked on the last *successful* login are persisted to
`$HOME/.cache/quickshell/greeter/last-session.json` (for the `greeter` system user, that's
`/var/lib/greeter/.cache/...` per the Installation steps above) and pre-filled/pre-selected on
the next boot. The session is matched by name, not list position, since discovery order isn't
guaranteed stable across boots. See `GreeterState.qml`'s `rememberLastLogin()`/`lastUsername`/
`lastSessionName`.
