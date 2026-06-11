# `osd` Module

Native **OSD (On-Screen Display)** for Quickshell/QML, adapted from the official
[`quickshell-examples` → `volume-osd`](https://github.com/quickshell-mirror/quickshell-examples/tree/master/volume-osd)
example and rewritten for **quickshell-d77** with a modular structure, the Tokyo Night
palette, an **ALSA** volume backend (with mute/unmute) and a **brightnessctl** brightness
backend.

A minimalist overlay (icon + progress bar + value) appears in the **top-right corner**
whenever the volume or screen brightness changes, and disappears after ~2.5 s.

![sample](../sample.png)

## What changed vs. the original example

| Original (`volume-osd`) | quickshell-d77 (`osd`) |
|-------------------------|------------------------|
| PipeWire backend (`Quickshell.Services.Pipewire`) | **ALSA** (`amixer`) with **mute/unmute** |
| Volume only | Volume **and** screen **brightness** (`brightnessctl`) |
| Bottom-centered | **Top-right corner** |
| Visible ~1 s | Visible ~**2.5 s** (configurable) |
| Single `shell.qml` | Reusable module with a public API + IPC |

## Module Contents

| File | Responsibility |
|------|----------------|
| `Osd.qml` | Main component: backends (ALSA + brightnessctl), change watcher, and the top-right overlay (icon + progress bar). Exposes the public API below. |
| `qmldir`  | Module definition (exports `Osd`). |

## How It Works

```text
keybind / IPC ──▶ Osd.volumeUp()  ──▶ amixer set Master 5%+  ──▶ reads level+mute ──▶ shows OSD (volume)
keybind / IPC ──▶ Osd.brightnessUp() ─▶ brightnessctl set 5%+ ─▶ reads %          ──▶ shows OSD (brightness)
                                   │
            background watcher (700 ms) detects *external* changes ───────────────▶ shows OSD too
```

1. The public functions run the corresponding ALSA/brightnessctl command and then read
   back the new value, set the overlay `mode` (`"volume"` or `"brightness"`), make it
   visible and restart the hide timer.
2. A lightweight background watcher polls volume and brightness every 700 ms. If a value
   changes **without** being triggered by us (e.g. media keys handled elsewhere, or
   another app changing the volume), the OSD is shown as well.
3. After `timeout` ms (default **2500**) with no further change, the overlay hides. It is
   created/destroyed via `LazyLoader`, so it uses no memory while hidden.

## Requirements

- **Quickshell** (`Quickshell`, `Quickshell.Io`).
- **ALSA** utilities — `amixer` (package `alsa-utils`). The default mixer control is
  `Master` (configurable via the `mixerControl` property).
- **brightnessctl** for screen brightness. The user must be able to run it without a
  password — usually granted by the `video` group + the udev rules shipped with
  brightnessctl (`/usr/lib/udev/rules.d/90-brightnessctl.rules`).
- A **Nerd Font** (the icons use Nerd Font glyphs). The default is
  `JetBrainsMono Nerd Font`.

## Installation

Place the `osd/` directory **next to** your `shell.qml` (typically in
`~/.config/quickshell/`):

```text
~/.config/quickshell/
├── shell.qml
└── osd/
    ├── Osd.qml
    ├── qmldir
    └── README.md
```

## Usage

In your `shell.qml`, import the module and instantiate `Osd`:

```qml
import "osd"

ShellRoot {
    Osd {
        id: osd
        // optional theming
        colPurple: "#bb9af7"
        colYellow: "#e0af68"
        step:      5      // % step for volume/brightness
        timeout:   2500   // ms the OSD stays visible
    }
}
```

### Trigger via IPC (Recommended)

`shell.qml` already exposes an `IpcHandler` with the `osd` target:

```bash
qs ipc call osd volumeUp           # volume +5% (shows OSD)
qs ipc call osd volumeDown         # volume -5%
qs ipc call osd volumeMuteToggle   # mute / unmute
qs ipc call osd brightnessUp       # brightness +5%
qs ipc call osd brightnessDown     # brightness -5%
qs ipc call osd showVolume         # just show the volume OSD
qs ipc call osd showBrightness     # just show the brightness OSD
```

### Hyprland keybinds (media keys)

Add to your `hyprland.conf` (`bindel` repeats while held; `bindl` works while locked):

```ini
bindel = , XF86AudioRaiseVolume,  exec, qs ipc call osd volumeUp
bindel = , XF86AudioLowerVolume,  exec, qs ipc call osd volumeDown
bindl  = , XF86AudioMute,         exec, qs ipc call osd volumeMuteToggle
bindel = , XF86MonBrightnessUp,   exec, qs ipc call osd brightnessUp
bindel = , XF86MonBrightnessDown, exec, qs ipc call osd brightnessDown
```

## `Osd` Public API

| Member | Type | Description |
|--------|------|-------------|
| `volumeUp()` | function | Raises volume by `step`% (ALSA) and shows the OSD. |
| `volumeDown()` | function | Lowers volume by `step`% and shows the OSD. |
| `volumeMuteToggle()` | function | Toggles ALSA mute/unmute and shows the OSD. |
| `brightnessUp()` | function | Increases brightness by `step`% (brightnessctl). |
| `brightnessDown()` | function | Decreases brightness by `step`%. |
| `showVolume()` | function | Reads and shows the volume OSD without changing it. |
| `showBrightness()` | function | Reads and shows the brightness OSD without changing it. |
| `step` | `int` | Step in % for volume/brightness (default `5`). |
| `timeout` | `int` | Time in ms the OSD stays visible (default `2500`). |
| `mixerControl` | `string` | ALSA control name (default `"Master"`). |
| `volLevel` | `int` | (Read-only) current volume 0–100. |
| `volMuted` | `bool` | (Read-only) `true` if muted. |
| `briLevel` | `int` | (Read-only) current brightness 0–100. |
| `colBg` … `colRed` | `color` | Theme colors (default: Tokyo Night palette). |
| `font`, `fsize` | `string` / `int` | Font family and base font size. |

## Customization

All theme properties can be overridden on the instance:

```qml
Osd {
    id: osd
    colPurple:    "#bb9af7"   // volume accent
    colYellow:    "#e0af68"   // brightness accent
    colRed:       "#f7768e"   // muted
    step:         10          // 10% steps
    timeout:      3000        // 3 s
    mixerControl: "Master"    // ALSA control
}
```
