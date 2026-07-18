import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Launcher native module (launcher dir).
// Exposes Launcher
import "launcher"

// Lockscreen native module (lockscreen dir).
// Exposes Lockscreen
import "lockscreen"

// OSD native module (osd dir).
// Exposes Osd (volume + brightness on-screen display)
import "osd"

// Dashboard native module (dashboard dir).
// Exposes Dashboard (quick info panel: stats, weather, cmus, session)
import "dashboard"

// Wallpaper picker module (wallpaper dir).
// Exposes Wallpaper
import "wallpaper"

// Music picker module (musicpicker dir).
// Exposes MusicPicker (Artist/Album search popup, plays via cmus)
import "musicpicker"

// Backdrop module (backdrop dir).
// Exposes Backdrop and WallpaperBackground (decorative background shown
// only while no wallpaper is set).
import "backdrop"

ShellRoot {
    // Note: i3 is deliberately not detected here. Every window in this shell
    // (bar, launcher, dashboard, lockscreen, wallpaper picker) is a Wayland
    // layer-shell surface (PanelWindow/WlrLayershell, WlSessionLock), which
    // requires a Wayland compositor implementing zwlr_layer_shell_v1. i3 is
    // an X11-only window manager, so none of these surfaces can render
    // under it regardless of detection — there is no "i3 support" to add.
    readonly property string compositor: {
        if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== null) return "hyprland";
        if (Quickshell.env("SWAYSOCK") !== null) return "sway";
        if (Quickshell.env("NIRI_SOCKET") !== null) return "niri";
        return "generic";
    }

    // ══════════════════════════════════════════════════════
    // BACKDROP (conditional decorative background)
    // ══════════════════════════════════════════════════════
    // One instance per screen, on the Bottom layer-shell layer (above
    // hyprpaper, which draws on the Background layer). Visible only while
    // Services.WallpaperState.hasWallpaper is false.
    WallpaperBackground {
        colBg:     g.colBg
        colFg:     g.colFg
        colPurple: g.colPurple
    }

    // ══════════════════════════════════════════════════════
    // LAUNCHER
    // ══════════════════════════════════════════════════════
    // Native launcher instance. It starts invisible and is
    // shown/hidden with appLauncher.toggle().
    // Uses the Tokyo Night palette and font defined in "g".
    Launcher {
        id: appLauncher
        colBg:     g.colBg
        colFg:     g.colFg
        colMuted:  g.colMuted
        colCyan:   g.colCyan
        colBlue:   g.colBlue
        colPurple: g.colPurple
        font:      g.font
        fsize:     g.fsize
        // Terminal used for apps with Terminal=true (adjust as needed).
        terminal:  "alacritty"
    }

    // ══════════════════════════════════════════════════════
    // WALLPAPER PICKER
    // ══════════════════════════════════════════════════════
    // Native wallpaper picker. Scans wallpaperDir for images
    // and applies the selection through hyprpaper (hyprctl IPC).
    // Toggle with wallpaperPicker.toggle().
    Wallpaper {
        id: wallpaperPicker
        colBg:     g.colBg
        colFg:     g.colFg
        colMuted:  g.colMuted
        colCyan:   g.colCyan
        colBlue:   g.colBlue
        colPurple: g.colPurple
        font:      g.font
        fsize:     g.fsize
        wallpaperDir: "$HOME/Wallpaper"
    }

    // ══════════════════════════════════════════════════════
    // LOCKSCREEN
    // ══════════════════════════════════════════════════════
    // Native lockscreen instance. It starts unlocked and is
    // triggered with lockScreen.lock().
    // Uses the Tokyo Night palette and font defined in "g".
    Lockscreen {
        id: lockScreen
        colBg:     g.colBg
        colFg:     g.colFg
        colMuted:  g.colMuted
        colBlue:   g.colBlue
        colPurple: g.colPurple
        colRed:    g.colRed
        font:      g.font
        fsize:     g.fsize
    }

    // ══════════════════════════════════════════════════════
    // OSD (On-Screen Display: volume + brightness)
    // ══════════════════════════════════════════════════════
    // Minimal overlay in the top-right corner, shown
    // for ~2.5 s whenever volume (ALSA) or brightness
    // (brightnessctl) changes. Controlled via IPC/keybinds.
    // Uses the Tokyo Night palette and font defined in "g".
    Osd {
        id: osd
        colBg:     g.colBg
        colFg:     g.colFg
        colMuted:  g.colMuted
        colBlue:   g.colBlue
        colPurple: g.colPurple
        colRed:    g.colRed
        colYellow: g.colYellow
        colGreen:  g.colGreen
        font:      g.font
        fsize:     g.fsize
        step:      5      // 5% step for volume and brightness
        timeout:   2500   // visible for 2.5 s
    }

    // ══════════════════════════════════════════════════════
    // DASHBOARD (quick panel: stats, weather, cmus, session)
    // ══════════════════════════════════════════════════════
    // Port of dashboard.py from fabric-d77. Appears in the top-left
    // corner, below the bar. Toggled via IPC (qs ipc call dashboard toggle)
    // or GlobalShortcut "dashboard" (suggestion: SUPER, I).
    Dashboard {
        id: dashboard
        colBg:     g.colBg
        colFg:     g.colFg
        colMuted:  g.colMuted
        colCyan:   g.colCyan
        colBlue:   g.colBlue
        colYellow: g.colYellow
        colGreen:  g.colGreen
        colRed:    g.colRed
        colPurple: g.colPurple
        font:      g.font
        fsize:     g.fsize

        // The bar automatically reserves an exclusive zone equal to its
        // height (margins.top + implicitHeight), and Hyprland already shifts
        // this window below that zone before applying margins.top.
        // So using the bar's own margins.top here is enough to leave
        // the same gap the bar has relative to the screen.
        marginTop:  bar.margins.top
        marginLeft: bar.margins.left

        onLockRequested:        lockScreen.lock()
        onLogoutRequested:      logoutProc.running = true
        onRebootRequested:      rebootProc.running = true
        onPoweroffRequested:    shutdownProc.running = true
        onMusicPickerRequested: musicPicker.open()
    }

    // ══════════════════════════════════════════════════════
    // MUSIC PICKER
    // ══════════════════════════════════════════════════════
    // Native Artist/Album picker. Scans musicDir for two-level Artist/Album
    // folders and plays the pick through Services.CmusControl (cmus).
    // Opened from Dashboard's "Browse albums" button or via IPC.
    MusicPicker {
        id: musicPicker
        colBg:     g.colBg
        colFg:     g.colFg
        colMuted:  g.colMuted
        colCyan:   g.colCyan
        colBlue:   g.colBlue
        colPurple: g.colPurple
        font:      g.font
        fsize:     g.fsize
    }

    // ══════════════════════════════════════════════════════
    // IPC (recommended way to control the launcher/session)
    // ══════════════════════════════════════════════════════
    // Exposes externally callable methods via:
    //   qs ipc call launcher toggle
    //   qs ipc call launcher open
    //   qs ipc call launcher close
    //   qs ipc call session  toggle | open | close
    //
    // It is the most reliable method to bind Hyprland keybinds.
    // Within Hyprland just call it with exec, e.g.:
    //   bind = SUPER, D, exec, qs ipc call launcher toggle
    // KEYBINDS.md has a more extensive explanation (incl. Lua).
    IpcHandler {
        target: "launcher"

        // Toggles the launcher's visibility (open if closed, close if open).
        function toggle(): void { appLauncher.toggle() }
        // Opens the launcher (and focuses the search field).
        function open(): void { appLauncher.open() }
        // Closes the launcher.
        function close(): void { appLauncher.close() }
    }

    IpcHandler {
        target: "session"

        // Toggles the session menu visibility.
        function toggle(): void { g.sessionOpen = !g.sessionOpen }
        // Opens the session menu.
        function open(): void { g.sessionOpen = true }
        // Closes the session menu.
        function close(): void { g.sessionOpen = false }
    }

    // Lockscreen IPC.
    //   qs ipc call lockscreen lock     (lock and ask for password via PAM)
    //   qs ipc call lockscreen unlock   (unlock without password)
    //   qs ipc call lockscreen toggle   (alternate)
    // Suggested Hyprland keybind:
    //   bind = SUPER, L, exec, qs ipc call lockscreen lock
    IpcHandler {
        target: "lockscreen"

        // Locks the screen (stays locked until a valid password is typed via PAM).
        function lock(): void { lockScreen.lock() }
        // Unlocks the screen without a password.
        function unlock(): void { lockScreen.unlock() }
        // Alternates between locked/unlocked.
        function toggle(): void { lockScreen.toggle() }
    }

    // OSD IPC (volume via ALSA + brightness via brightnessctl).
    // Ideal for binding to multimedia keys in Hyprland:
    //   bindel = , XF86AudioRaiseVolume, exec, qs ipc call osd volumeUp
    //   bindel = , XF86AudioLowerVolume, exec, qs ipc call osd volumeDown
    //   bindl  = , XF86AudioMute,        exec, qs ipc call osd volumeMuteToggle
    //   bindel = , XF86MonBrightnessUp,  exec, qs ipc call osd brightnessUp
    //   bindel = , XF86MonBrightnessDown,exec, qs ipc call osd brightnessDown
    IpcHandler {
        target: "osd"

        // Raises the volume (step defined in Osd.step) and shows the OSD.
        function volumeUp(): void { osd.volumeUp() }
        // Lowers the volume and shows the OSD.
        function volumeDown(): void { osd.volumeDown() }
        // Toggles mute/unmute and shows the OSD.
        function volumeMuteToggle(): void { osd.volumeMuteToggle() }
        // Increases the brightness and shows the OSD.
        function brightnessUp(): void { osd.brightnessUp() }
        // Decreases the brightness and shows the OSD.
        function brightnessDown(): void { osd.brightnessDown() }
        // Only shows the volume OSD (without changing it).
        function showVolume(): void { osd.showVolume() }
        // Only shows the brightness OSD (without changing it).
        function showBrightness(): void { osd.showBrightness() }
    }

    // Dashboard IPC (quick info/session panel).
    //   qs ipc call dashboard toggle
    //   qs ipc call dashboard open
    //   qs ipc call dashboard close
    // Example bind in hyprland.conf:
    //   bind = SUPER, I, exec, qs ipc call dashboard toggle
    IpcHandler {
        target: "dashboard"

        // Toggles the panel visibility.
        function toggle(): void { dashboard.toggle() }
        // Opens the panel.
        function open(): void { dashboard.open() }
        // Closes the panel.
        function close(): void { dashboard.close() }
    }

    // Wallpaper picker IPC.
    //   qs ipc call wallpaper toggle
    //   qs ipc call wallpaper open
    //   qs ipc call wallpaper close
    //   qs ipc call wallpaper reload
    //   qs ipc call wallpaper set /path/to/image.png
    //   qs ipc call wallpaper random
    //   qs ipc call wallpaper clear
    //
    // Example bind in hyprland.conf:
    //   bind = SUPER, W, exec, qs ipc call wallpaper toggle
    IpcHandler {
        target: "wallpaper"

        // Toggles the picker visibility.
        function toggle(): void { wallpaperPicker.toggle() }
        // Opens the picker and rescans the directory.
        function open(): void { wallpaperPicker.open() }
        // Closes the picker.
        function close(): void { wallpaperPicker.close() }
        // Rescans the directory without opening/closing the picker.
        function reload(): void { wallpaperPicker.reload() }
        // Applies a wallpaper directly by path, without opening the picker.
        // Useful in scripts: qs ipc call wallpaper set /home/daniel/Wallpaper/foo.png
        function set(path: string): void { wallpaperPicker.apply(path) }
        // Applies a random wallpaper from the already-loaded list.
        function random(): void { wallpaperPicker.applyRandom() }
        // Removes the active wallpaper: unloads from hyprpaper and deletes the
        // state file. The backdrop (decorative background) becomes
        // visible automatically while no wallpaper is set.
        function clear(): void { wallpaperPicker.clear() }
    }

    // Music picker IPC.
    //   qs ipc call musicpicker toggle
    //   qs ipc call musicpicker open
    //   qs ipc call musicpicker close
    //   qs ipc call musicpicker reload
    //
    // Example bind in hyprland.conf:
    //   bind = SUPER, M, exec, qs ipc call musicpicker toggle
    IpcHandler {
        target: "musicpicker"

        // Toggles the picker visibility.
        function toggle(): void { musicPicker.toggle() }
        // Opens the picker and rescans musicDir.
        function open(): void { musicPicker.open() }
        // Closes the picker.
        function close(): void { musicPicker.close() }
        // Rescans musicDir without opening/closing the picker.
        function reload(): void { musicPicker.reload() }
        // Plays an album directly by path, without opening the picker.
        // Useful in scripts: qs ipc call musicpicker play "/home/daniel/Música/Artist/Album"
        function play(path: string): void { musicPicker.playPath(path) }
    }

    // ── Global Hyprland keybinds (fallback, loaded only on Hyprland) ──
    Loader {
        active: compositor === "hyprland"
        source: "HyprlandShortcuts.qml"
        onLoaded: {
            item.appLauncher = appLauncher;
            item.globalState = g;
            item.lockScreen = lockScreen;
            item.dashboard = dashboard;
        }
    }

    // ══════════════════════════════════════════════════════
    // GLOBAL STATE
    // ══════════════════════════════════════════════════════
    QtObject {
        id: g
        property color colBg:     "#1a1b26"
        property color colFg:     "#a9b1d6"
        property color colMuted:  "#444b6a"
        property color colCyan:   "#0db9d7"
        property color colBlue:   "#7aa2f7"
        property color colYellow: "#e0af68"
        property color colGreen:  "#9ece6a"
        property color colRed:    "#f7768e"
        property color colPurple: "#bb9af7"
        property string font:     "JetBrainsMono Nerd Font"
        property int    fsize:    13

        property int    cpuUsage:    0
        property int    memUsage:    0
        property int    volLevel:    0
        property bool   volMuted:    false
        property int    batLevel:    100
        property bool   batCharging: false
        property string wifiSSID:    "..."
        property int    wifiSignal:  0

        property var lastCpuIdle:  0
        property var lastCpuTotal: 0

        property bool sessionOpen: false

        // Set whenever a session action (suspend/reboot/poweroff/logout)
        // fails — e.g. no login1 provider (systemd-logind/elogind) reachable
        // on D-Bus. Cleared automatically by sessionErrorTimer.
        property string sessionError: ""
    }

    // ══════════════════════════════════════════════════════
    // SYSTEM PROCESSES
    // ══════════════════════════════════════════════════════

    // Reads the current Master volume level (percentage) via ALSA.
    Process {
        id: volProc
        command: ["sh", "-c", "amixer get Master | grep -Po '\\[\\d+%\\]' | head -1 | tr -d '[]%'"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim() !== "")
                    g.volLevel = parseInt(data.trim())
            }
        }
        Component.onCompleted: running = true
    }

    // Checks whether the Master channel is muted.
    Process {
        id: volMuteCheckProc
        command: ["sh", "-c", "amixer get Master | grep -q '\\[off\\]' && echo 1 || echo 0"]
        stdout: SplitParser {
            onRead: data => {
                if (data) g.volMuted = (data.trim() === "1")
            }
        }
        Component.onCompleted: running = true
    }

    // One-shot volume control processes (triggered on user interaction).
    Process { id: volUpProc;   command: ["amixer", "set", "Master", "5%+"];    running: false }
    Process { id: volDownProc; command: ["amixer", "set", "Master", "5%-"];    running: false }
    Process { id: volMuteProc; command: ["amixer", "set", "Master", "toggle"]; running: false }

    // Reads aggregate CPU usage from /proc/stat between samples.
    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var p     = data.trim().split(/\s+/)
                var idle  = parseInt(p[4]) + parseInt(p[5])
                var total = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0)
                if (g.lastCpuTotal > 0) {
                    var dT = total - g.lastCpuTotal
                    var dI = idle  - g.lastCpuIdle
                    g.cpuUsage = dT > 0 ? Math.round(100 * (1 - dI / dT)) : 0
                }
                g.lastCpuTotal = total
                g.lastCpuIdle  = idle
            }
        }
        Component.onCompleted: running = true
    }

    // Reads memory usage percentage from `free`.
    Process {
        id: memProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var p = data.trim().split(/\s+/)
                g.memUsage = Math.round(100 * (parseInt(p[2]) || 0) / (parseInt(p[1]) || 1))
            }
        }
        Component.onCompleted: running = true
    }

    // Reads the battery charge level (falls back to 100 if unavailable).
    Process {
        id: batProc
        command: ["sh", "-c", "bat=$(ls /sys/class/power_supply/ 2>/dev/null | grep -m1 '^BAT'); [ -n \"$bat\" ] && cat /sys/class/power_supply/$bat/capacity 2>/dev/null || echo 100"]
        stdout: SplitParser {
            onRead: data => { if (data.trim()) g.batLevel = parseInt(data.trim()) }
        }
        Component.onCompleted: running = true
    }

    // Reads the battery charging status.
    Process {
        id: batStatusProc
        command: ["sh", "-c", "bat=$(ls /sys/class/power_supply/ 2>/dev/null | grep -m1 '^BAT'); [ -n \"$bat\" ] && cat /sys/class/power_supply/$bat/status 2>/dev/null || echo Discharging"]
        stdout: SplitParser {
            onRead: data => { g.batCharging = data.trim() === "Charging" }
        }
        Component.onCompleted: running = true
    }

    // Reads the currently connected Wi-Fi SSID and signal quality
    // (shows "Disconnected" if none).
    Process {
        id: wifiProc
        command: ["sh", "-c", "LANG=C nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep -m1 '^yes' || echo 'no::0'"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                var parts = line !== "" ? line.split(":") : []
                if (parts.length >= 3 && parts[1] !== "") {
                    g.wifiSSID   = parts[1]
                    g.wifiSignal = parseInt(parts[2]) || 0
                } else {
                    g.wifiSSID   = "Disconnected"
                    g.wifiSignal = 0
                }
            }
        }
        Component.onCompleted: running = true
    }

    // Opens nmtui in a floating terminal (same logic as the dashboard).
    Process {
        id: nmtuiBarProc
        running: false
        command: ["sh", "-c", dashboard.nmtuiLaunchCommand()]
    }

    // Session processes (triggered from the dashboard and the session menu).
    // All go through the freedesktop login1 D-Bus interface via `loginctl`,
    // which is implemented both by systemd-logind (e.g. Arch) and by
    // elogind (e.g. Void with a Wayland desktop) — so the same command
    // works unmodified on either. `systemctl` is tried as a second attempt
    // only for the rare case where loginctl itself isn't on PATH but
    // systemd is; if both fail, the combined stderr is surfaced via
    // g.sessionError (see sessionErrorBanner below) instead of silently
    // doing nothing.
    function _sessionCmd(action) {
        return ["sh", "-c", "loginctl " + action + " 2>&1 || systemctl " + action + " 2>&1"]
    }
    // Builds the error banner text from whatever the command printed (e.g.
    // "Failed to issue method call: Caller does not belong to any known
    // session."), falling back to a generic hint if it printed nothing.
    function _sessionFailMsg(label, output) {
        var out = output.trim()
        return label + " failed" + (out !== "" ? ": " + out : " — no systemd-logind/elogind reachable?")
    }

    Process {
        id: suspendProc
        command: _sessionCmd("suspend")
        running: false
        property string _out: ""
        stdout: SplitParser { onRead: line => suspendProc._out += line + " " }
        onExited: function(code) {
            if (code !== 0) g.sessionError = _sessionFailMsg("Suspend", suspendProc._out)
            suspendProc._out = ""
        }
    }
    Process {
        id: rebootProc
        command: _sessionCmd("reboot")
        running: false
        property string _out: ""
        stdout: SplitParser { onRead: line => rebootProc._out += line + " " }
        onExited: function(code) {
            if (code !== 0) g.sessionError = _sessionFailMsg("Reboot", rebootProc._out)
            rebootProc._out = ""
        }
    }
    Process {
        id: shutdownProc
        command: _sessionCmd("poweroff")
        running: false
        property string _out: ""
        stdout: SplitParser { onRead: line => shutdownProc._out += line + " " }
        onExited: function(code) {
            if (code !== 0) g.sessionError = _sessionFailMsg("Poweroff", shutdownProc._out)
            shutdownProc._out = ""
        }
    }
    Process {
        id: logoutProc
        property string _out: ""
        command: {
            if (compositor === "hyprland") return ["hyprctl", "dispatch", "hl.dsp.exit()"];
            if (compositor === "sway") return ["swaymsg", "exit"];
            // niri-session runs niri as a systemd --user service and waits
            // on it; killing the login1 session from the outside (loginctl
            // terminate-session) detaches the display but leaves
            // niri.service marked active, so the *next* login's
            // niri-session refuses to start ("niri session is already
            // running") — a known niri issue (niri-wm/niri#2729). Quitting
            // niri natively lets its own service wrapper notice the exit
            // and clean up niri.service correctly, so prefer that here.
            if (compositor === "niri") return ["niri", "msg", "action", "quit", "--skip-confirmation"];
            // "self" resolves the caller's session by looking up its PID's
            // cgroup, which fails with "Caller does not belong to any
            // known session" when the compositor runs as a systemd --user
            // service (e.g. Hyprland under UWSM) — the caller then lives
            // under user@<uid>.service rather than the login
            // session-N.scope, so logind can't map it back. Session
            // managers that do this import $XDG_SESSION_ID into the
            // environment specifically to work around it, so prefer that
            // and only fall back to "self" if it's unset.
            return ["sh", "-c", "loginctl terminate-session \"${XDG_SESSION_ID:-self}\" 2>&1"];
        }
        running: false
        stdout: SplitParser { onRead: line => logoutProc._out += line + " " }
        onExited: function(code) {
            if (code !== 0) g.sessionError = _sessionFailMsg("Logout", logoutProc._out)
            logoutProc._out = ""
        }
    }

    Timer {
        id: sessionErrorTimer
        interval: 5000
        onTriggered: g.sessionError = ""
    }
    Connections {
        target: g
        function onSessionErrorChanged() {
            if (g.sessionError !== "")
                sessionErrorTimer.restart()
        }
    }

    // Periodically refresh all the polled system stats.
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running          = true
            memProc.running          = true
            volProc.running          = true
            volMuteCheckProc.running = true
            batProc.running          = true
            batStatusProc.running    = true
            wifiProc.running         = true
        }
    }

    // ══════════════════════════════════════════════════════
    // BAR
    // ══════════════════════════════════════════════════════
    PanelWindow {
        id: bar
        anchors.top:   true
        anchors.left:  true
        anchors.right: true
        margins.right: 10
        margins.left:  10
        margins.top:   10
        implicitHeight: 40
        // Transparent window so the rounded background Rectangle below
        // defines the visible shape of the bar.
        color: "transparent"

        // Rounded background of the bar (radius: 10).
        Rectangle {
            id: barBackground
            anchors.fill: parent
            radius: 10
            color: g.colBg

            RowLayout {
                anchors.fill:    parent
                anchors.margins: 6
                spacing: 6

                // ── Launcher ──────────────────────────────────
                Rectangle {
                    width: 26
                    height: 26
                    radius: 6
                    color: launchMa.containsMouse ? Qt.lighter(g.colPurple, 1.3) : g.colPurple

                    Text {
                        anchors.centerIn: parent
                        text: "󰍜"
                        font { family: g.font; pixelSize: 10 }
                        color: g.colBg
                    }
                    MouseArea {
                        id: launchMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: appLauncher.toggle()
                    }
                }

                Rectangle { width: 1; height: 18; color: g.colMuted }

                // ── Workspaces (Loaded Dynamically) ──────────
                Loader {
                    id: workspacesLoader
                    source: {
                        if (compositor === "hyprland") return "workspaces/WorkspacesHyprland.qml";
                        if (compositor === "sway") return "workspaces/WorkspacesSway.qml";
                        if (compositor === "niri") return "workspaces/WorkspacesNiri.qml";
                        return "";
                    }
                    onLoaded: {
                        item.globalState = g;
                    }
                }

                Item { Layout.fillWidth: true }

                // ── CPU ───────────────────────────────────────
                RowLayout {
                    spacing: 3
                    Text {
                        text: " "
                        font { family: g.font; pixelSize: g.fsize + 1 }
                        color: g.colYellow
                    }
                    Text {
                        text: g.cpuUsage + "%"
                        font { family: g.font; pixelSize: g.fsize }
                        color: g.cpuUsage > 80 ? g.colRed : g.cpuUsage > 50 ? g.colYellow : g.colGreen
                    }
                }

                Rectangle { width: 1; height: 18; color: g.colMuted }

                // ── RAM ───────────────────────────────────────
                RowLayout {
                    spacing: 3
                    Text {
                        text: "  "
                        font { family: g.font; pixelSize: g.fsize + 1 }
                        color: g.colCyan
                    }
                    Text {
                        text: g.memUsage + "%"
                        font { family: g.font; pixelSize: g.fsize }
                        color: g.memUsage > 80 ? g.colRed : g.memUsage > 60 ? g.colYellow : g.colCyan
                    }
                }

                Rectangle { width: 1; height: 18; color: g.colMuted }

                // ── Volume ────────────────────────────────────
                // Wrapped in an Item so the MouseArea can fill the widget
                // without conflicting with the Layout's anchor management.
                Item {
                    implicitWidth:  volRow.implicitWidth
                    implicitHeight: volRow.implicitHeight

                    RowLayout {
                        id: volRow
                        anchors.fill: parent
                        spacing: 3
                        Text {
                            text: g.volMuted ? "󰝟 " : (g.volLevel > 50 ? "󰕾 " : g.volLevel > 0 ? "󰖀 " : "󰕿 ")
                            font { family: g.font; pixelSize: g.fsize + 1 }
                            color: g.volMuted ? g.colRed : g.colPurple
                        }
                        Text {
                            text: g.volLevel + "%"
                            font { family: g.font; pixelSize: g.fsize }
                            color: g.volMuted ? g.colMuted : g.colFg
                        }
                    }

                    // Left click toggles mute; scroll wheel adjusts volume.
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            volMuteProc.running = true
                            volProc.running     = true
                        }
                        onWheel: (wheel) => {
                            if (wheel.angleDelta.y > 0) volUpProc.running = true
                            else                        volDownProc.running = true
                            // Refresh the displayed value immediately.
                            volProc.running          = true
                            volMuteCheckProc.running = true
                        }
                    }
                }

                Rectangle { width: 1; height: 18; color: g.colMuted }

                // ── Wi-Fi ─────────────────────────────────────
                // Clicking opens nmtui in a floating terminal.
                RowLayout {
                    spacing: 3
                    Text {
                        text: g.wifiSSID === "Disconnected" ? "󰤭 " : "󰤨 "
                        font { family: g.font; pixelSize: g.fsize + 1 }
                        color: g.wifiSSID === "Disconnected" ? g.colRed : g.colBlue
                    }
                    Text {
                        text: g.wifiSSID === "Disconnected" ? g.wifiSSID : g.wifiSSID + " " + g.wifiSignal + "%"
                        font { family: g.font; pixelSize: g.fsize }
                        color: g.colFg
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: nmtuiBarProc.running = true
                    }
                }

                Rectangle { width: 1; height: 18; color: g.colMuted }

                // ── Battery ───────────────────────────────────
                // Clicking cycles the power profile (power-profiles-daemon)
                // and shows the result in the OSD.
                RowLayout {
                    spacing: 3
                    Text {
                        text: g.batCharging ? "󰂄 "
                            : g.batLevel > 80 ? "󰁹 "
                            : g.batLevel > 60 ? "󰂀 "
                            : g.batLevel > 40 ? "󰁾 "
                            : g.batLevel > 20 ? "󰁼 "
                            : "󰁺 "
                        font { family: g.font; pixelSize: g.fsize + 1 }
                        color: g.batLevel < 20 ? g.colRed : g.batLevel < 50 ? g.colYellow : g.colGreen
                    }
                    Text {
                        text: g.batLevel + "%"
                        font { family: g.font; pixelSize: g.fsize }
                        color: g.batLevel < 20 ? g.colRed : g.batLevel < 50 ? g.colYellow : g.colGreen
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: osd.cyclePowerProfile()
                    }
                }

                Rectangle { width: 1; height: 18; color: g.colMuted }

                // ── Clock ─────────────────────────────────────
                Text {
                    id: clock
                    color: g.colBlue
                    font { family: g.font; pixelSize: g.fsize; bold: true }
                    text: Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm:ss")
                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm:ss")
                    }
                }

                Rectangle { width: 1; height: 18; color: g.colMuted }

                // ── Session Button ────────────────────────────
                Rectangle {
                    width: 26
                    height: 26
                    radius: 6
                    color: sessBtnMa.containsMouse || g.sessionOpen
                        ? g.colRed
                        : Qt.rgba(0.97, 0.46, 0.56, 0.3)

                    Text {
                        anchors.centerIn: parent
                        text: "⏻"
                        font.pixelSize: 14
                        color: g.colRed
                    }
                    MouseArea {
                        id: sessBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: g.sessionOpen = !g.sessionOpen
                    }
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════
    // SESSION POPUP
    // ══════════════════════════════════════════════════════
    PanelWindow {
        id: sessionPopup
        visible: g.sessionOpen
        color: "transparent"

        anchors.top:    true
        anchors.bottom: true
        anchors.left:   true
        anchors.right:  true

        WlrLayershell.layer:         WlrLayer.Overlay
        WlrLayershell.namespace:     "quickshell-session"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: {
            if (visible) {
                sessionBox.currentIndex = 0
                sessionBox.forceActiveFocus()
            }
        }

        // Dimmed backdrop; clicking it closes the menu.
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.35)
            MouseArea {
                anchors.fill: parent
                onClicked: g.sessionOpen = false
            }
        }

        // ── Central session menu box ──────────────────────
        Rectangle {
            id: sessionBox
            anchors.centerIn: parent
            width:  220
            height: 256
            radius: 12
            color: Qt.darker(g.colBg, 1.4)
            border.color: g.colRed
            border.width: 2

            property int currentIndex: 0

            readonly property var sessionActions: [
                null, suspendProc, rebootProc, shutdownProc, logoutProc
            ]

            function activateSelected() {
                g.sessionOpen = false
                if (currentIndex === 0) lockScreen.lock()
                else                    sessionActions[currentIndex].running = true
            }

            focus: true
            Keys.onUpPressed:     currentIndex = (currentIndex - 1 + sessionActions.length) % sessionActions.length
            Keys.onDownPressed:   currentIndex = (currentIndex + 1) % sessionActions.length
            Keys.onEscapePressed: g.sessionOpen = false
            Keys.onReturnPressed: activateSelected()
            Keys.onEnterPressed:  activateSelected()

            // Swallow clicks inside the box so they don't reach the backdrop.
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill:    parent
                anchors.margins: 10
                spacing: 4

                // Lock
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 6
                    color: (ma0.containsMouse || sessionBox.currentIndex === 0) ? Qt.rgba(0.48, 0.64, 0.97, 0.2) : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        spacing: 8
                        Text {
                            text: "󰌾"
                            font { family: g.font; pixelSize: g.fsize + 10 }
                            color: g.colBlue
                        }
                        Text {
                            text: "Lock"
                            font { family: g.font; pixelSize: g.fsize + 1 }
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: g.colFg
                        }
                    }
                    MouseArea {
                        id: ma0
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: sessionBox.currentIndex = 0
                        onClicked: {
                            g.sessionOpen = false
                            lockScreen.lock()
                        }
                    }
                }

                // Suspend
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 6
                    color: (ma1.containsMouse || sessionBox.currentIndex === 1) ? Qt.rgba(0.88, 0.69, 0.41, 0.2) : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        spacing: 8
                        Text {
                            text: "󰒲"
                            font { family: g.font; pixelSize: g.fsize + 10 }
                            color: g.colYellow
                        }
                        Text {
                            text: "Suspend"
                            font { family: g.font; pixelSize: g.fsize + 1 }
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: g.colFg
                        }
                    }
                    MouseArea {
                        id: ma1
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: sessionBox.currentIndex = 1
                        onClicked: {
                            g.sessionOpen = false
                            suspendProc.running = true
                        }
                    }
                }

                // Reboot
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 6
                    color: (ma2.containsMouse || sessionBox.currentIndex === 2) ? Qt.rgba(0.88, 0.69, 0.41, 0.2) : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        spacing: 8
                        Text {
                            text: "󰑓"
                            font { family: g.font; pixelSize: g.fsize + 10 }
                            color: g.colYellow
                        }
                        Text {
                            text: "Reboot"
                            font { family: g.font; pixelSize: g.fsize + 1 }
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: g.colFg
                        }
                    }
                    MouseArea {
                        id: ma2
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: sessionBox.currentIndex = 2
                        onClicked: {
                            g.sessionOpen = false
                            rebootProc.running = true
                        }
                    }
                }

                // Shutdown
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 6
                    color: (ma3.containsMouse || sessionBox.currentIndex === 3) ? Qt.rgba(0.97, 0.46, 0.56, 0.2) : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        spacing: 8
                        Text {
                            text: "󰐥"
                            font { family: g.font; pixelSize: g.fsize + 10 }
                            color: g.colRed
                        }
                        Text {
                            text: "Shutdown"
                            font { family: g.font; pixelSize: g.fsize + 1 }
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: g.colFg
                        }
                    }
                    MouseArea {
                        id: ma3
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: sessionBox.currentIndex = 3
                        onClicked: {
                            g.sessionOpen = false
                            shutdownProc.running = true
                        }
                    }
                }

                // Logout
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 6
                    color: (ma4.containsMouse || sessionBox.currentIndex === 4) ? Qt.rgba(0.27, 0.29, 0.42, 0.5) : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        spacing: 8
                        Text {
                            text: "󰍃"
                            font { family: g.font; pixelSize: g.fsize + 10 }
                            color: g.colMuted
                        }
                        Text {
                            text: "Logout"
                            font { family: g.font; pixelSize: g.fsize + 1 }
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: g.colFg
                        }
                    }
                    MouseArea {
                        id: ma4
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: sessionBox.currentIndex = 4
                        onClicked: {
                            g.sessionOpen = false
                            logoutProc.running = true
                        }
                    }
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════
    // SESSION ERROR BANNER
    // Small auto-hiding toast for when a session action (suspend/
    // reboot/poweroff/logout) fails — e.g. no systemd-logind/elogind on
    // D-Bus. Independent of sessionPopup, which is already closed by the
    // time a Process can fail.
    // ══════════════════════════════════════════════════════
    PanelWindow {
        id: sessionErrorBanner
        visible: g.sessionError !== ""
        color: "transparent"

        anchors.top: true
        margins.top: 50

        WlrLayershell.layer:         WlrLayer.Overlay
        WlrLayershell.namespace:     "quickshell-session-error"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0

        // Empty mask → does not block mouse events (matches Osd.qml).
        mask: Region {}

        // Real D-Bus/systemd error text can run long (e.g. "Failed to
        // issue method call: Caller does not belong to any known
        // session."), so cap the width and wrap instead of stretching
        // across the screen.
        implicitWidth:  Math.min(bannerText.implicitWidth + 40, 640)
        implicitHeight: bannerText.implicitHeight + 24

        Rectangle {
            id: banner
            anchors.fill: parent
            radius: 8
            color: Qt.darker(g.colBg, 1.2)
            border.color: g.colRed
            border.width: 2

            Text {
                id: bannerText
                anchors.centerIn: parent
                width: Math.min(implicitWidth, 600)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: g.sessionError
                font { family: g.font; pixelSize: g.fsize }
                color: g.colRed
            }
        }
    }
}
