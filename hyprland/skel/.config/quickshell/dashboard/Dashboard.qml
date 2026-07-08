// ══════════════════════════════════════════════════════
// Dashboard.qml
// Quick-info overlay in the top-left corner
// (below the bar): CPU/RAM/temperature/disk, weather,
// cmus controls, nmtui shortcut, and session actions.
//
// Port of dashboard.py from fabric-d77 to native quickshell,
// keeping the same Tokyo Night palette and the same data
// sources (/proc, wttr.in, cmus-remote, iw/nmcli).
//
// Public API (normally triggered via IPC / keybinds):
//   toggle() — opens/closes the panel
//   open()   — opens the panel
//   close()  — closes the panel
// ══════════════════════════════════════════════════════
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: dash

    // ── Theme (Tokyo Night by default; can be overridden) ──
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

    // Position: below the bar, aligned to the left.
    property int marginTop:  60
    property int marginLeft: 10

    // ── Session signals (connect to lockScreen/procs in shell.qml) ──
    signal lockRequested()
    signal logoutRequested()
    signal rebootRequested()
    signal poweroffRequested()

    // ══════════════════════════════════════════════════════
    // STATE
    // ══════════════════════════════════════════════════════
    property int    cpuPercent:  0
    property int    ramPercent:  0
    property string tempText:    "N/A"
    property int    diskPercent: 0
    property string weatherText: "loading…"

    property bool   cmusRunning: false
    property string cmusStatus:  "stopped"
    property string cmusTrack:   "—"

    property string netIcon:  "󰤮"
    property string netLabel: "Network configuration"

    property string terminal: "xterm"
    property var    _termCandidates: ["foot", "kitty", "alacritty", "wezterm", "xterm"]
    property int    _termIdx: 0

    property real _lastCpuIdle:  0
    property real _lastCpuTotal: 0

    // ── Public API ───────────────────────────────────────
    function open() {
        visible = true
        weatherText = "loading…"
        weatherProc.running = true
        _refreshAll()
        focusItem.forceActiveFocus()
    }
    function close() {
        visible = false
    }
    function toggle() {
        if (visible) close()
        else         open()
    }

    function _refreshAll() {
        cpuProc.running       = true
        ramProc.running       = true
        tempProc.running      = true
        diskProc.running      = true
        cmusProc.running      = true
        netProc.running       = true
    }

    // ══════════════════════════════════════════════════════
    // LAYER SHELL WINDOW
    // ══════════════════════════════════════════════════════
    visible: false
    color: "transparent"

    implicitWidth:  400
    implicitHeight: mainCol.implicitHeight + 32

    anchors.top:  true
    anchors.left: true
    margins.top:  dash.marginTop
    margins.left: dash.marginLeft

    exclusiveZone: 0

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace:     "quickshell-dashboard"

    // ── Terminal detection (for the nmtui shortcut) ─────────
    Process {
        id: termDetect
        command: ["sh", "-c", "command -v " + dash._termCandidates[dash._termIdx]]
        running: true
        stdout: SplitParser {
            onRead: function (line) {
                dash.terminal = dash._termCandidates[dash._termIdx]
            }
        }
        onExited: function (code) {
            if (code !== 0 && dash._termIdx + 1 < dash._termCandidates.length) {
                dash._termIdx++
                termDetect.running = true
            }
        }
    }

    // ══════════════════════════════════════════════════════
    // PROCESSES — periodic state reads
    // ══════════════════════════════════════════════════════

    // CPU: delta from /proc/stat (same method as the bar).
    Process {
        id: cpuProc
        running: false
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var p     = data.trim().split(/\s+/)
                var idle  = parseInt(p[4]) + parseInt(p[5])
                var total = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0)
                if (dash._lastCpuTotal > 0) {
                    var dT = total - dash._lastCpuTotal
                    var dI = idle  - dash._lastCpuIdle
                    dash.cpuPercent = dT > 0 ? Math.round(100 * (1 - dI / dT)) : 0
                }
                dash._lastCpuTotal = total
                dash._lastCpuIdle  = idle
            }
        }
    }

    // RAM.
    Process {
        id: ramProc
        running: false
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var p = data.trim().split(/\s+/)
                dash.ramPercent = Math.round(100 * (parseInt(p[2]) || 0) / (parseInt(p[1]) || 1))
            }
        }
    }

    // CPU temperature: tries `sensors`, falls back to thermal_zone0.
    Process {
        id: tempProc
        running: false
        command: ["sh", "-c", 'command -v sensors >/dev/null 2>&1 && t=$(sensors 2>/dev/null | grep -m1 -E "Package id 0|Tctl|Tdie" | grep -oE "[0-9]+\\.[0-9]+" | head -1); if [ -z "$t" ]; then z=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null); [ -n "$z" ] && t=$(( z / 1000 )); fi; echo "$t"']
        stdout: SplitParser {
            onRead: data => {
                var t = data ? data.trim() : ""
                dash.tempText = t !== "" ? Math.round(parseFloat(t)) + "°C" : "N/A"
            }
        }
    }

    // Disk (root partition).
    Process {
        id: diskProc
        running: false
        command: ["sh", "-c", "df --output=pcent / | tail -1 | tr -d '% '"]
        stdout: SplitParser {
            onRead: data => {
                var v = parseInt(data ? data.trim() : "")
                dash.diskPercent = isNaN(v) ? 0 : v
            }
        }
    }

    // Weather (wttr.in), one request per open().
    Process {
        id: weatherProc
        running: false
        command: ["sh", "-c", "curl -s --max-time 6 -A 'curl/7.0' 'https://wttr.in/?format=3' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = text.trim()
                dash.weatherText = t !== "" ? t : "weather unavailable"
            }
        }
    }

    // cmus state.
    Process {
        id: cmusProc
        running: false
        command: ["cmus-remote", "-Q"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "") {
                    dash.cmusRunning = false
                    dash.cmusStatus  = "stopped"
                    dash.cmusTrack   = "—"
                    return
                }
                var status = "stopped", artist = "", title = ""
                text.split("\n").forEach(line => {
                    if (line.startsWith("status "))
                        status = line.slice(7).trim()
                    else if (line.startsWith("tag artist "))
                        artist = line.slice(11).trim()
                    else if (line.startsWith("tag title "))
                        title = line.slice(10).trim()
                })
                var track = (artist && title) ? (artist + " — " + title) : (title || "—")
                if (track.length > 42) track = track.slice(0, 40) + "…"
                dash.cmusRunning = true
                dash.cmusStatus  = status
                dash.cmusTrack   = track
            }
        }
        onExited: function (code) {
            if (code !== 0) {
                dash.cmusRunning = false
                dash.cmusStatus  = "stopped"
                dash.cmusTrack   = "—"
            }
        }
    }

    // Network state (wifi / wired / offline).
    Process {
        id: netProc
        running: false
        command: ["sh", "-c", 'for i in /sys/class/net/*; do ifc=$(basename "$i"); if [ -d "$i/wireless" ]; then ssid=$(iw dev "$ifc" link 2>/dev/null | grep "SSID:" | head -1 | cut -d: -f2-); ssid="${ssid# }"; if [ -n "$ssid" ]; then echo "wifi|Connected to $ssid"; exit 0; fi; fi; done; for i in /sys/class/net/*; do ifc=$(basename "$i"); [ "$ifc" = "lo" ] && continue; [ -d "$i/wireless" ] && continue; [ -e "$i/device" ] || continue; if [ -f "$i/carrier" ] && [ "$(cat "$i/carrier" 2>/dev/null)" = "1" ]; then echo "wired|Connected ($ifc)"; exit 0; fi; done; echo "offline|Network configuration"']
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split("|")
                var kind  = parts[0]
                var label = parts.length > 1 ? parts[1] : "Network configuration"
                if (label.length > 34) label = label.slice(0, 32) + "…"
                dash.netIcon  = kind === "wifi" ? "󰖩" : kind === "wired" ? "󰈀" : "󰤮"
                dash.netLabel = label
            }
        }
    }

    // Refreshes the cards while the panel is visible.
    Timer {
        interval: 2000
        running: dash.visible
        repeat: true
        onTriggered: dash._refreshAll()
    }

    // ── cmus: actions (one-shot) ────────────────────────────
    Process { id: cmusPrevProc;  command: ["cmus-remote", "-r"]; running: false; onExited: cmusProc.running = true }
    Process { id: cmusToggleProc; command: ["cmus-remote", "-u"]; running: false; onExited: cmusProc.running = true }
    Process { id: cmusNextProc;  command: ["cmus-remote", "-n"]; running: false; onExited: cmusProc.running = true }

    // Starts cmus in a detached tmux/screen session.
    // The environment (XDG_RUNTIME_DIR/HOME) is passed explicitly to cmus,
    // because an existing/old tmux session may have inherited different
    // variables from the original tmux server, causing cmus to write its
    // control socket somewhere cmus-remote cannot find.
    Process {
        id: cmusStartProc
        running: false
        command: ["sh", "-c",
            'tmux kill-session -t cmus >/dev/null 2>&1; ' +
            'command -v tmux >/dev/null 2>&1 && { tmux new-session -d -s cmus "XDG_RUNTIME_DIR=' + Quickshell.env("XDG_RUNTIME_DIR") + ' HOME=' + Quickshell.env("HOME") + ' cmus"; exit 0; }; ' +
            'command -v screen >/dev/null 2>&1 && { screen -dmS cmus sh -c "XDG_RUNTIME_DIR=' + Quickshell.env("XDG_RUNTIME_DIR") + ' HOME=' + Quickshell.env("HOME") + ' exec cmus"; exit 0; }; ' +
            'exit 1']
        onExited: cmusRestartTimer.start()
    }

    // Small delay before re-querying cmus: right after startup
    // (inside tmux) the process has not yet finished initialising its
    // library or creating the control socket.
    Timer {
        id: cmusRestartTimer
        interval: 1200
        onTriggered: {
            cmusProc.running = true
        }
    }

    // Shell command that opens nmtui in a floating terminal
    // (window marked with class "nmtui-float", see windowrule
    // in hyprland.lua). Also reused by the bar.
    function nmtuiLaunchCommand() {
        return dash.terminal === "wezterm"
            ? "setsid wezterm start --class nmtui-float -- nmtui >/dev/null 2>&1 &"
            : "setsid " + dash.terminal + " --class nmtui-float -e nmtui >/dev/null 2>&1 &"
    }

    // Opens nmtui in a floating terminal and closes the panel.
    Process {
        id: nmtuiProc
        running: false
        command: ["sh", "-c", dash.nmtuiLaunchCommand()]
    }

    // ══════════════════════════════════════════════════════
    // LAYOUT
    // ══════════════════════════════════════════════════════
    // Invisible item to capture Escape (closes the panel).
    Item {
        id: focusItem
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: dash.close()
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Qt.rgba(0.10, 0.11, 0.15, 0.96)
        border.color: g_border()
        border.width: 1

        function g_border() { return Qt.rgba(0.27, 0.29, 0.42, 0.6) }

        MouseArea { anchors.fill: parent } // prevent clicks from passing through

        ColumnLayout {
            id: mainCol
            anchors {
                fill: parent
                margins: 16
            }
            spacing: 10

            // ── System cards ─────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // CPU
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 78
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.04)
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text { text: "󰍜"; font.family: dash.font; font.pixelSize: 20; color: dash.colYellow; Layout.alignment: Qt.AlignHCenter }
                        Text { text: dash.cpuPercent + "%"; font.family: dash.font; font.pixelSize: dash.fsize + 1; font.bold: true; color: dash.colFg; Layout.alignment: Qt.AlignHCenter }
                        Text { text: "CPU"; font.family: dash.font; font.pixelSize: dash.fsize - 3; color: dash.colMuted; Layout.alignment: Qt.AlignHCenter }
                    }
                }

                // RAM
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 78
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.04)
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text { text: ""; font.family: dash.font; font.pixelSize: 20; color: dash.colCyan; Layout.alignment: Qt.AlignHCenter }
                        Text { text: dash.ramPercent + "%"; font.family: dash.font; font.pixelSize: dash.fsize + 1; font.bold: true; color: dash.colFg; Layout.alignment: Qt.AlignHCenter }
                        Text { text: "RAM"; font.family: dash.font; font.pixelSize: dash.fsize - 3; color: dash.colMuted; Layout.alignment: Qt.AlignHCenter }
                    }
                }

                // TEMP
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 78
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.04)
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text { text: "󰔏"; font.family: dash.font; font.pixelSize: 20; color: dash.colRed; Layout.alignment: Qt.AlignHCenter }
                        Text { text: dash.tempText; font.family: dash.font; font.pixelSize: dash.fsize + 1; font.bold: true; color: dash.colFg; Layout.alignment: Qt.AlignHCenter }
                        Text { text: "TEMP"; font.family: dash.font; font.pixelSize: dash.fsize - 3; color: dash.colMuted; Layout.alignment: Qt.AlignHCenter }
                    }
                }

                // DISK
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 78
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.04)
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text { text: "󰋊"; font.family: dash.font; font.pixelSize: 20; color: dash.colBlue; Layout.alignment: Qt.AlignHCenter }
                        Text { text: dash.diskPercent + "%"; font.family: dash.font; font.pixelSize: dash.fsize + 1; font.bold: true; color: dash.colFg; Layout.alignment: Qt.AlignHCenter }
                        Text { text: "DISK"; font.family: dash.font; font.pixelSize: dash.fsize - 3; color: dash.colMuted; Layout.alignment: Qt.AlignHCenter }
                    }
                }
            }

            // ── Weather ────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 56
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.04)
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    Text { text: "󰖐"; font.family: dash.font; font.pixelSize: 22; color: dash.colBlue }
                    Text {
                        text: dash.weatherText
                        font.family: dash.font; font.pixelSize: dash.fsize
                        color: dash.colFg
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            // ── cmus ─────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 56
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.04)
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text { text: "󰎈"; font.family: dash.font; font.pixelSize: 22; color: dash.colPurple }

                    // State: running — track + controls.
                    RowLayout {
                        visible: dash.cmusRunning
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            text: dash.cmusTrack
                            font.family: dash.font; font.pixelSize: dash.fsize
                            color: dash.colFg
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        RowLayout {
                            spacing: 2
                            Text {
                                text: ""
                                font.family: dash.font; font.pixelSize: 18
                                color: dash.colFg
                                MouseArea { anchors.fill: parent; onClicked: cmusPrevProc.running = true }
                            }
                            Text {
                                text: dash.cmusStatus === "playing" ? "" : ""
                                font.family: dash.font; font.pixelSize: 18
                                color: dash.colFg
                                MouseArea { anchors.fill: parent; onClicked: cmusToggleProc.running = true }
                            }
                            Text {
                                text: ""
                                font.family: dash.font; font.pixelSize: 18
                                color: dash.colFg
                                MouseArea { anchors.fill: parent; onClicked: cmusNextProc.running = true }
                            }
                        }
                    }

                    // State: stopped — headless start button.
                    // Note: MouseArea cannot be a direct child of
                    // RowLayout (the Layout ignores `anchors` on its
                    // children), so it goes in a plain Item on top.
                    Item {
                        visible: !dash.cmusRunning
                        Layout.fillWidth: true
                        implicitHeight: startRow.implicitHeight
                        RowLayout {
                            id: startRow
                            anchors.fill: parent
                            spacing: 8
                            Text {
                                text: ""
                                font.family: dash.font; font.pixelSize: 16
                                color: dash.colFg
                            }
                            Text {
                                text: "Start cmus"
                                font.family: dash.font; font.pixelSize: dash.fsize
                                color: dash.colFg
                            }
                            Item { Layout.fillWidth: true }
                        }
                        MouseArea { anchors.fill: parent; onClicked: cmusStartProc.running = true }
                    }
                }
            }

            // ── Network (nmtui) ─────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 56
                radius: 8
                color: netMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    Text { text: dash.netIcon; font.family: dash.font; font.pixelSize: 22; color: dash.colFg }
                    Text {
                        text: dash.netLabel
                        font.family: dash.font; font.pixelSize: dash.fsize
                        color: dash.colFg
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                MouseArea {
                    id: netMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        dash.close()
                        nmtuiProc.running = true
                    }
                }
            }

            // ── Session ────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: 8
                    color: lockMa.containsMouse ? Qt.rgba(0.48, 0.64, 0.97, 0.2) : Qt.rgba(1, 1, 1, 0.04)
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "󰌾"; font.family: dash.font; font.pixelSize: 20; color: dash.colBlue; Layout.alignment: Qt.AlignHCenter }
                        Text { text: "Lock"; font.family: dash.font; font.pixelSize: dash.fsize - 2; color: dash.colFg; Layout.alignment: Qt.AlignHCenter }
                    }
                    MouseArea { id: lockMa; anchors.fill: parent; hoverEnabled: true; onClicked: { dash.close(); dash.lockRequested() } }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: 8
                    color: logoutMa.containsMouse ? Qt.rgba(0.27, 0.29, 0.42, 0.5) : Qt.rgba(1, 1, 1, 0.04)
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "󰍃"; font.family: dash.font; font.pixelSize: 20; color: dash.colMuted; Layout.alignment: Qt.AlignHCenter }
                        Text { text: "Log Out"; font.family: dash.font; font.pixelSize: dash.fsize - 2; color: dash.colFg; Layout.alignment: Qt.AlignHCenter }
                    }
                    MouseArea { id: logoutMa; anchors.fill: parent; hoverEnabled: true; onClicked: { dash.close(); dash.logoutRequested() } }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: 8
                    color: rebootMa.containsMouse ? Qt.rgba(0.88, 0.69, 0.41, 0.2) : Qt.rgba(1, 1, 1, 0.04)
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "󰑓"; font.family: dash.font; font.pixelSize: 20; color: dash.colYellow; Layout.alignment: Qt.AlignHCenter }
                        Text { text: "Reboot"; font.family: dash.font; font.pixelSize: dash.fsize - 2; color: dash.colFg; Layout.alignment: Qt.AlignHCenter }
                    }
                    MouseArea { id: rebootMa; anchors.fill: parent; hoverEnabled: true; onClicked: { dash.close(); dash.rebootRequested() } }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: 8
                    color: poweroffMa.containsMouse ? Qt.rgba(0.97, 0.46, 0.56, 0.2) : Qt.rgba(1, 1, 1, 0.04)
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "󰐥"; font.family: dash.font; font.pixelSize: 20; color: dash.colRed; Layout.alignment: Qt.AlignHCenter }
                        Text { text: "Power Off"; font.family: dash.font; font.pixelSize: dash.fsize - 2; color: dash.colFg; Layout.alignment: Qt.AlignHCenter }
                    }
                    MouseArea { id: poweroffMa; anchors.fill: parent; hoverEnabled: true; onClicked: { dash.close(); dash.poweroffRequested() } }
                }
            }
        }
    }
}
