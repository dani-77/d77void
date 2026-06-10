# `lockscreen` Module

Native lockscreen for Quickshell/QML, based on the official
[`quickshell-examples`](https://github.com/quickshell-mirror/quickshell-examples/tree/master/lockscreen)
implementation, adapted for **quickshell-d77** with a modular structure, Tokyo Night color palette, and a public API (`lock`/`unlock`/`toggle`) ready to be connected to **IPC**.

Authentication is handled through **PAM password authentication** (`pam_unix`). It uses the Wayland `ext-session-lock-v1` protocol (`WlSessionLock`), providing secure screen locking—the compositor ensures that nothing remains accessible underneath.

![sample](../sample.png)

## Module Contents

| File | Responsibility |
|------|----------------|
| `Lockscreen.qml` | Main component: wraps `WlSessionLock` + `LockContext` and exposes `lock()`, `unlock()`, `toggle()`, and the `locked` property. |
| `LockContext.qml` | Shared state across monitors + PAM authentication (`PamContext`). |
| `LockSurface.qml` | Per-monitor UI: clock, date, and password field (Tokyo Night style). |
| `pam/password.conf` | Dedicated PAM configuration (`auth required pam_unix.so`). |
| `qmldir` | Module definition (exports the components above). |

## How It Works

```text
Lockscreen ──contains──▶ WlSessionLock ──per monitor──▶ LockSurface
     │                    │
     └──── LockContext (PAM) ◀────┘
```

1. `Lockscreen.lock()` sets `WlSessionLock.locked = true`. The compositor locks the session and displays a `LockSurface` on every monitor.
2. The user enters their password; when pressing Enter (or clicking the **Unlock** button), `LockContext` validates it through PAM (`pam/password.conf`).
3. On success, `LockContext` emits `unlocked()` and `Lockscreen` releases the lock (`locked = false`). On failure, it displays "Incorrect password".

> ⚠️ The PAM configuration (`pam/password.conf`) is resolved **relative** to `LockContext.qml`. Keep the `pam/` directory inside `lockscreen/`.

## Installation

The `lockscreen/` directory should be placed **next to** your `shell.qml`
(typically in `~/.config/quickshell/`):

```text
~/.config/quickshell/
├── shell.qml
└── lockscreen/
    ├── Lockscreen.qml
    ├── LockContext.qml
    ├── LockSurface.qml
    ├── qmldir
    └── pam/
        └── password.conf
```

## Usage

In your `shell.qml`, import the module using a relative path and instantiate `Lockscreen`:

```qml
import "lockscreen"

ShellRoot {
    Lockscreen { id: lockScreen }

    // Lock/unlock from anywhere:
    // lockScreen.lock()
    // lockScreen.unlock()
}
```

### Trigger via IPC (Recommended)

Your `shell.qml` already exposes an `IpcHandler` with the `lockscreen` target:

```bash
qs ipc call lockscreen lock      # lock the screen
qs ipc call lockscreen unlock    # unlock (without password)
qs ipc call lockscreen toggle    # toggle state
```

And in `hyprland.conf`:

```ini
bind = SUPER, L, exec, qs ipc call lockscreen lock
```

See [`KEYBINDS.md`](../KEYBINDS.md) for the complete configuration (including Lua integration).

## `Lockscreen` Public API

| Member | Type | Description |
|---------|------|-------------|
| `lock()` | function | Locks the screen (requires PAM password authentication to unlock). |
| `unlock()` | function | Unlocks immediately, **without** requiring a password (e.g., for automation). |
| `toggle()` | function | Toggles between locked and unlocked states. |
| `locked` | `bool` | (Read-only) `true` while the screen is locked. |
| `didLock()` | signal | Emitted when the screen is locked. |
| `didUnlock()` | signal | Emitted when the screen is unlocked. |
| `colBg` … `colRed` | `color` | Theme colors (default: Tokyo Night palette). |
| `font`, `fsize` | `string` / `int` | Font family and base font size. |

## Customization

All theme properties can be overridden in the component instance:

```qml
Lockscreen {
    id: lockScreen
    colBg:     "#1a1b26"
    colPurple: "#bb9af7"
    fsize:     14
}
```

## Requirements

- **Quickshell** with PAM support (`Quickshell.Services.Pam`) and Wayland session lock support (`Quickshell.Wayland.WlSessionLock`).
- A Wayland compositor that implements `ext-session-lock-v1` (e.g., Hyprland).
- PAM configured on the system (`pam_unix` is used to validate the user's password).
