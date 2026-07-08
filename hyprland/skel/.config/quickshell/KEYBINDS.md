# Keybinds (Hyprland) — quickshell-d77

This document explains how to trigger the **launcher**, the **session menu** and the
**lockscreen** of quickshell-d77 from Hyprland keybinds (tested with **Hyprland
0.46+**), both in the native format (`hyprland.conf` / hyprlang) and in
configurations generated/written via **Lua**.

There are **two** ways to do this:

1. **IPC (recommended)** — Hyprland calls `qs ipc call <target> <function>` with a
   simple `exec`. This is the most reliable approach, especially with Lua configs,
   and the one this repository now uses by default.
2. **Global shortcuts (fallback)** — Quickshell registers shortcuts via the
   `hyprland-global-shortcuts-v1` protocol and Hyprland binds them with the
   `global` dispatcher. Kept as an alternative, but more fragile.

| Action                                | IPC Target / Function        | Suggested keybind   |
|---------------------------------------|------------------------------|---------------------|
| Toggle the application launcher       | `launcher` → `toggle`        | `SUPER + D`         |
| Toggle the session menu               | `session`  → `toggle`        | `SUPER + SHIFT + E` |
| Lock the screen                       | `lockscreen` → `lock`        | `SUPER + L`         |
| Show Wallpaper dir contents           | `wallpaper`  → `toggle`      | `SUPER + Y`         |
| Toggle the info dashboard             | `dashboard`  → `toggle`      | `SUPER + I`         |

The `launcher`, `session`, `wallpaper` and `dashboard` targets each expose three functions:
`toggle`, `open`, and `close`. The `lockscreen` target exposes `lock`, `unlock`, and `toggle`.

---

## 1. IPC — the recommended approach

### 1.1. How it works

Two `IpcHandler`s (from the `Quickshell.Io` module) are declared in `shell.qml`:

```qml
import Quickshell.Io

IpcHandler {
    target: "launcher"
    function toggle(): void { appLauncher.toggle() }
    function open():   void { appLauncher.open() }
    function close():  void { appLauncher.close() }
}

IpcHandler {
    target: "session"
    function toggle(): void { g.sessionOpen = !g.sessionOpen }
    function open():   void { g.sessionOpen = true }
    function close():  void { g.sessionOpen = false }
}

IpcHandler {
    target: "wallpaper"
    function toggle(): void { g.sessionOpen = !g.sessionOpen }
    function open():   void { g.sessionOpen = true }
    function close():  void { g.sessionOpen = false }
}

IpcHandler {
    target: "lockscreen"
    function lock():   void { lockScreen.lock() }    // lock (asks for password via PAM)
    function unlock(): void { lockScreen.unlock() }  // unlock without a password
    function toggle(): void { lockScreen.toggle() }  // alternate
}
```

> 🔒 The `lockscreen` target is backed by the native **lockscreen** module (folder
> `lockscreen/`, based on quickshell-examples). `lock` uses a real `WlSessionLock`
> and validates the password through **PAM**, so the screen stays locked until a
> valid password is typed (or `unlock` is called from an already-authenticated
> mechanism). See `lockscreen/README.md` for details.

While Quickshell is running, any process can invoke these functions from the
command line:

```bash
qs ipc call launcher toggle     # toggle the launcher
qs ipc call launcher open       # open the launcher
qs ipc call launcher close      # close the launcher

qs ipc call session toggle      # toggle the session menu
qs ipc call session open        # open the session menu
qs ipc call session close       # close the session menu

qs ipc call wallpaper toggle      # toggle the wallpaper menu
qs ipc call wallpaper open        # open the walmenu menu
qs ipc call wallpaper close       # close the wallpaper menu

qs ipc call lockscreen lock     # lock the screen (asks for password via PAM)
qs ipc call lockscreen unlock   # unlock without a password
qs ipc call lockscreen toggle   # alternate locked/unlocked
```

> 💡 If you run Quickshell with more than one instance/config, you can target the
> IPC with `qs -c <config> ipc call ...` or via `--pid`. For the normal case
> (a single instance), `qs ipc call ...` is enough.

To inspect what is exposed:

```bash
qs ipc show          # lists all available targets and functions
```

### 1.2. hyprland.conf (hyprlang)

Add the following to your `~/.config/hypr/hyprland.conf`:

```ini
# ── quickshell-d77 (via IPC) ──────────────────────────────
# Application launcher (SUPER + D)
bind = SUPER, D, exec, qs ipc call launcher toggle

# Session menu: lock / suspend / reboot / shutdown / logout (SUPER + SHIFT + E)
bind = SUPER SHIFT, E, exec, qs ipc call session toggle

# Wallpaper menu (SUPER + Y)
bind = SUPER, Y, exec, qs ipc call wallpaper toggle

# Lock the screen (SUPER + L)
bind = SUPER, L, exec, qs ipc call lockscreen lock

# Info dashboard (SUPER + I)
bind = SUPER, I, exec, qs ipc call dashboard toggle
```

General format:

```
bind = <modifiers>, <key>, exec, qs ipc call <target> <function>
```

After editing, reload Hyprland:


```bash
hyprctl reload
```

### 1.3. Lua configuration (Hyprland 0.46+)

Hyprland reads its config in **hyprlang**. When people talk about a "Lua config",
it usually refers to a Lua script that **generates** the `hyprland.conf` (or a file
included via `source`), or that applies binds at runtime. In all cases the goal is
to produce `bind = ..., exec, qs ipc call ...` lines.

#### 3a. Lua that generates/writes the `hyprland.conf`

```lua
-- keybinds.lua — generates the quickshell-d77 bind lines (via IPC)
local binds = {
  -- { mods,         key, "qs ipc call <target> <function>" }
  { "SUPER",       "D", "qs ipc call launcher toggle" },
  { "SUPER SHIFT", "E", "qs ipc call session toggle"  },
  { "SUPER",       "L", "qs ipc call lockscreen lock" },
  { "SUPER",       "Y", "qs ipc call wallpaper toggle" },
}

local lines = {}
for _, b in ipairs(binds) do
  lines[#lines + 1] = string.format("bind = %s, %s, exec, %s", b[1], b[2], b[3])
end

-- Append to the end of hyprland.conf
local path = os.getenv("HOME") .. "/.config/hypr/hyprland.conf"
local f = assert(io.open(path, "a"))
f:write("\n# quickshell-d77 (IPC)\n")
f:write(table.concat(lines, "\n") .. "\n")
f:close()
```

Result written to `hyprland.conf`:

```ini
bind = SUPER, D, exec, qs ipc call launcher toggle
bind = SUPER SHIFT, E, exec, qs ipc call session toggle
bind = SUPER, Y, exec, qs ipc call wallpaper toggle
bind = SUPER, L, exec, qs ipc call lockscreen lock
bind = SUPER, I, exec, qs ipc call dashboard toggle
```

#### 3b. `init.lua` (Lua dotfiles frameworks)

If you use a wrapper/framework whose `init.lua` defines keybinds through a table
(a common pattern in dotfiles), the `exec` maps directly to the IPC command. The
example below is generic — adapt the field names to your framework:

```lua
-- ~/.config/hypr/init.lua
local hypr = require("hypr")   -- depends on your framework

hypr.bind({
  { mods = "SUPER",       key = "D", dispatcher = "exec", arg = "qs ipc call launcher toggle" },
  { mods = "SUPER SHIFT", key = "E", dispatcher = "exec", arg = "qs ipc call session toggle"  },
  { mods = "SUPER",       key = "L", dispatcher = "exec", arg = "qs ipc call lockscreen lock" },
  { mods = "SUPER",       key = "Y", dispatcher = "exec", arg = "qs ipc call wallpaper toggle" },
  { mods = "SUPER",       key = "I", dispatcher = "exec", arg = "qs ipc call dashboard toggle" },
})
```

If your `init.lua` only emits config strings, use approach 3a. If it applies binds
at runtime, see 3c.

#### 3c. `hyprctl keyword` from Lua (runtime)

```lua
-- applies the binds immediately in the current session (not persistent)
local cmds = {
  'hyprctl keyword bind "SUPER, D, exec, qs ipc call launcher toggle"',
  'hyprctl keyword bind "SUPER SHIFT, E, exec, qs ipc call session toggle"',
  'hyprctl keyword bind "SUPER, L, exec, qs ipc call lockscreen lock"',
  'hyprctl keyword bind "SUPER, Y, exec, qs ipc call wallpaper toggle"',
  'hyprctl keyword bind "SUPER, I, exec, qs ipc call dashboard toggle"',
}
for _, c in ipairs(cmds) do
  os.execute(c)
end
```

> Note: binds applied via `hyprctl keyword` only apply to the current session.
> To make them permanent, generate them in `hyprland.conf` (3a) or use `source =`.

#### 3d. `source` a file generated by Lua

Keep `hyprland.conf` clean and let Lua generate a separate file:

In `hyprland.conf`:
```ini
source = ~/.config/hypr/generated/quickshell-binds.conf
```

And the Lua script writes `~/.config/hypr/generated/quickshell-binds.conf` with the
`bind` lines from section 3a.

---

## 2. Global shortcuts (fallback)

`shell.qml` still registers two `GlobalShortcut`s (from the `Quickshell.Hyprland`
module) as an alternative to IPC:

```qml
GlobalShortcut {
    appid: "quickshell"   // bind prefix (default: "quickshell")
    name: "launcher"      // shortcut identifier
    description: "Toggle the application launcher"
    onPressed: appLauncher.toggle()
}
```

On the Hyprland side, you bind a key to the shortcut with the **`global`
dispatcher** and the `<appid>:<name>` argument:

```ini
# ── quickshell-d77 (via global shortcuts) ─────────────────
bind = SUPER, D, global, quickshell:launcher
bind = SUPER SHIFT, E, global, quickshell:session
bind = SUPER, L, global, quickshell:lock
bind = SUPER, Y, global, quickshell:wallpaper
bind = SUPER, I, global, quickshell:dashboard
```

`shell.qml` also registers a `quickshell:lock` shortcut that locks the screen via the
native lockscreen module (`onPressed: lockScreen.lock()`).

General format:

```
bind = <modifiers>, <key>, global, <appid>:<name>
```

> ⚠️ **Important:** the shortcut is only available **while Quickshell is
> running**. It is Quickshell that registers the `appid:name`; Hyprland merely
> invokes it. With Lua-generated configs, this path tends to be more fragile than
> IPC — which is why section 1 is the recommended approach.

---

## 3. How to test

### Step 1 — Confirm that Quickshell is running

```bash
qs -p ~/.config/quickshell/shell.qml &
# or confirm the process:
pgrep -af quickshell
```

### Step 2 (IPC) — List and test the exposed targets

```bash
qs ipc show                       # should list the "launcher", "session" and "lockscreen" targets
qs ipc call launcher toggle       # the launcher should toggle
qs ipc call session toggle        # the session menu should toggle
qs ipc call wallpaper toggle        # the wallpaper menu should toggle
qs ipc call lockscreen lock       # the screen should lock (type your password to unlock)
```

### Step 2 (global shortcuts) — List the registered shortcuts

```bash
hyprctl globalshortcuts
```

You should see something like:

```
quickshell:launcher -> Toggle the application launcher
quickshell:session -> Toggle the session menu (lock/suspend/reboot/...)
quickshell:lock -> Lock the screen (native lockscreen)
quickshell:wallpaper -> Toggle the wallpaper menu
```

### Step 3 — Confirm the binds in Hyprland

```bash
hyprctl binds | grep -A4 -E "qs ipc call|global"
```

### Step 4 — Test in practice

- Press `SUPER + D` → the launcher should toggle.
- Press `SUPER + SHIFT + E` → the session menu should toggle.
- Press `SUPER + L` → the screen should lock (type your password to unlock).
- Press `SUPER + Y` → the wallpaper menu should toggle.
---

## 4. Troubleshooting

| Symptom | Likely cause | Solution |
|---------|--------------|----------|
| `qs ipc call ...` says it cannot find the target | Quickshell is not running, or uses another `shell.qml` | Start `qs -p ~/.config/quickshell/shell.qml` and confirm with `qs ipc show` |
| `qs ipc show` does not list `launcher`/`session` | The `shell.qml` in use does not have the `IpcHandler`s | Make sure you are using the `shell.qml` from this repository |
| The key does nothing | Missing the `bind ... exec, qs ipc call ...` (or `global ...`) | Add the bind (section 1.2 or 2) and run `hyprctl reload` |
| The key does **something else** | `SUPER+D` is already assigned to another bind | Remove/change the conflicting bind, or use a different key |
| Stopped working after a restart | Bind applied only via `hyprctl keyword` | Make it permanent in `hyprland.conf` (1.2 / 3a / 3d) |
| `hyprctl globalshortcuts` empty (fallback mode) | Quickshell is not running | Start Quickshell |

Also check for keybind conflicts and the Hyprland version:

```bash
hyprctl binds | grep -i "D$"   # binds attached to the D key
hyprctl version
```

---

## 5. Quick summary (IPC)

1. Make sure Quickshell is running: `qs -p ~/.config/quickshell/shell.qml`
2. Add to `hyprland.conf` (or generate via Lua):
   ```ini
   bind = SUPER, D, exec, qs ipc call launcher toggle
   bind = SUPER SHIFT, E, exec, qs ipc call session toggle
   bind = SUPER, L, exec, qs ipc call lockscreen lock
   bind = SUPER, Y, exec, qs ipc call wallpaper toggle
   bind = SUPER, I, exec, qs ipc call dashboard toggle
   ```
3. `hyprctl reload`
4. Verify: `qs ipc show`
5. Test `SUPER+D`, `SUPER+SHIFT+E`, `SUPER+Y`, `SUPER+L` and `SUPER+I`.
