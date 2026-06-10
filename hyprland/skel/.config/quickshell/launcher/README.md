# `launcher` Module

A **Rofi / Fuzzel**-style application launcher, written 100% in QML/Quickshell —
with no external dependencies. It scans the system's `.desktop` files, displays a
centered floating window with a search field and a keyboard-navigable list, and
runs the selected application.

![sample](../sample.png)

## Module contents

| File                     | Responsibility |
|--------------------------|------------------|
| `Launcher.qml`           | Main component: window (layer-shell `Overlay`), search and results list. |
| `AppLoader.qml`          | Connects the scanner to the parser and exposes the app list + `filter()`. |
| `DesktopDirScanner.qml`  | Scans the default directories and returns the raw contents of the `.desktop` files. |
| `desktopParser.js`       | JS library that parses the `.desktop` files and handles filtering. |
| `qmldir`                 | Module definition (exposes the components above). |
| `example-integration.qml`| Example of how to enable the launcher from `shell.qml`. |

## How it works

```
DesktopDirScanner  ──(raw text)──▶  desktopParser.js  ──(array of apps)──▶  AppLoader  ──▶  Launcher
```

1. **DesktopDirScanner** runs a `Process` that traverses, in order of priority:
   - `~/.local/share/applications`
   - `/usr/local/share/applications`
   - `/usr/share/applications`

   and concatenates all `*.desktop` files separated by the `===DESKTOP_FILE_START===` delimiter.
2. **desktopParser.js** interprets the `[Desktop Entry]` section, cleans up the *field codes*
   from `Exec` (`%U`, `%f`, ...), discards `NoDisplay`/`Hidden` entries and sorts them by name.
3. **AppLoader** keeps the `apps` array and provides `reload()` and `filter(query)`.
4. **Launcher** renders the UI, performs reactive filtering as you search, and runs the
   app via `setsid <exec> &` (apps with `Terminal=true` are opened in the configured terminal).

## Installation

The `launcher/` folder must sit **next to** your `shell.qml`
(by default in `~/.config/quickshell/`):

```
~/.config/quickshell/
├── shell.qml
└── launcher/
    ├── Launcher.qml
    ├── AppLoader.qml
    ├── DesktopDirScanner.qml
    ├── desktopParser.js
    └── qmldir
```

## Usage

In your `shell.qml`, import the module by its relative path and instantiate the `Launcher`:

```qml
import "launcher"

ShellRoot {
    Launcher { id: appLauncher }

    // Open/close from anywhere:
    // appLauncher.toggle()
}
```

### Opening via a bar button

Replace the click that used to call `fuzzel`:

```qml
// Before:
// onClicked: { launcherProc.command = ["fuzzel"]; launcherProc.running = true }

// After:
onClicked: appLauncher.toggle()
```

### Opening via a global shortcut (Hyprland)

```qml
import Quickshell.Hyprland

GlobalShortcut {
    name: "launcher"
    description: "Opens the application launcher"
    onPressed: appLauncher.toggle()
}
```

And in `hyprland.conf`:

```
bind = SUPER, D, global, quickshell:launcher
```

See `example-integration.qml` for a complete, runnable example.

## Public API of `Launcher`

| Member          | Type       | Description |
|-----------------|------------|-----------|
| `open()`        | function   | Shows the launcher, reloads the apps and focuses the search. |
| `hide()`        | function   | Hides the launcher. |
| `toggle()`      | function   | Toggles between open/closed. |
| `terminal`      | `string`   | Terminal used for `Terminal=true` apps (default: `"foot"`). |
| `colBg` … `colPurple` | `color` | Theme colors (default: Tokyo Night palette, same as `shell.qml`). |
| `font`, `fsize` | `string`/`int` | Base font and size. |

## Keyboard shortcuts

| Key                | Action |
|--------------------|------|
| Type               | Filters the application list |
| `↑` / `↓`          | Moves the selection |
| `Tab`              | Next item |
| `Enter`            | Runs the selected app |
| `Esc`              | Closes the launcher |
| Click outside      | Closes the launcher |

## Customization

All theme properties can be overridden on the instance:

```qml
Launcher {
    id: appLauncher
    colBg:     "#1a1b26"
    colPurple: "#bb9af7"
    terminal:  "kitty"
    fsize:     14
}
```

To change the searched directories, adjust the `dirs` property of the
`DesktopDirScanner` (inside `AppLoader.qml`).
