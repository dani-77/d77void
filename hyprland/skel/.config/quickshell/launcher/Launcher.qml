// ══════════════════════════════════════════════════════
// Launcher.qml
// Quickshell native Rofi style Launcher.
// Floating window centered with search field and
// apps list scrollable with keyboard.
// ══════════════════════════════════════════════════════
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: launcher

    // ══════════════════════════════════════════════════════
    // THEME (Tokyo Night)
    // ══════════════════════════════════════════════════════
    property color colBg:     "#1a1b26"
    property color colFg:     "#a9b1d6"
    property color colMuted:  "#444b6a"
    property color colCyan:   "#0db9d7"
    property color colBlue:   "#7aa2f7"
    property color colPurple: "#bb9af7"
    property string font:     "JetBrainsMono Nerd Font"
    property int    fsize:    13

    // Terminal for apps with Terminal=true.
    // Auto-detected at startup from the preferred list below.
    // Override in shell.qml if you want to force a specific one.
    property string terminal: "kitty"
    property var _termCandidates: ["alacritty", "kitty", "foot", "wezterm", "xterm"]
    property int _termIdx: 0

    Process {
        id: termDetect
        command: ["sh", "-c", "command -v " + launcher._termCandidates[launcher._termIdx]]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                launcher.terminal = launcher._termCandidates[launcher._termIdx]
            }
        }
        onExited: function(code) {
            if (code !== 0) {
                if (launcher._termIdx + 1 < launcher._termCandidates.length) {
                    launcher._termIdx++
                    termDetect.running = true
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════
    // STATE
    // ══════════════════════════════════════════════════════
    property string query: ""
    // appLoader.apps reference
    property var    results: {
        appLoader.apps
        return appLoader.filter(query)
    }
    property int    selected: 0

    // ── Public API ───────────────────────────────────────
    function open() {
        searchField.text = ""
        query    = ""
        selected = 0
        visible  = true
        appLoader.reload()
        searchField.forceActiveFocus()
    }
    function hide() {
        visible = false
    }
    // Alias for IPC API (toggle/open/close).
    function close() {
        hide()
    }
    function toggle() {
        if (visible) hide()
        else         open()
    }

    // ── Moves selection keeping inside parameters ──────
    function moveSelection(delta) {
        if (results.length === 0) {
            selected = 0
            return
        }
        var n = (selected + delta) % results.length
        if (n < 0) n += results.length
        selected = n
    }

    // ── Executes selected app ─────────────────────────
    function launchSelected() {
        if (results.length === 0)
            return
        launch(results[selected])
    }

    function launch(app) {
        if (!app || !app.exec)
            return

        var cmd = app.exec.replace(/%[uUfFdDnNickvm]/g, "").trim()
        if (app.terminal)
            cmd = launcher.terminal + " -e " + cmd

        launchProc.command = ["sh", "-c", "setsid " + cmd + " >/dev/null 2>&1 &"]
        launchProc.running = true
        hide()
    }

    onResultsChanged: selected = 0

    // ══════════════════════════════════════════════════════
    // LAYER SHELL WINDOW
    // ══════════════════════════════════════════════════════
    visible: false
    color: "transparent"

    implicitWidth:  560
    implicitHeight: 420

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace:     "quickshell-launcher"

    Process { id: launchProc; running: false }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        MouseArea {
            anchors.fill: parent
            onClicked: launcher.hide()
        }
    }

    // ══════════════════════════════════════════════════════
    // LAUNCHER BOX
    // ══════════════════════════════════════════════════════
    Rectangle {
        id: box
        anchors.centerIn: parent
        width:  parent.width
        height: parent.height
        radius: 12
        color: launcher.colBg
        border.color: launcher.colPurple
        border.width: 2

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill:    parent
            anchors.margins: 14
            spacing: 10

            // ── Search field ────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 8
                color: Qt.darker(launcher.colBg, 1.3)
                border.color: searchField.activeFocus ? launcher.colPurple : launcher.colMuted
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin:  12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: ""
                        font.family: launcher.font
                        font.pixelSize: launcher.fsize + 2
                        color: launcher.colPurple
                    }

                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        clip: true
                        color: launcher.colFg
                        font.family: launcher.font
                        font.pixelSize: launcher.fsize + 1
                        selectionColor: launcher.colPurple
                        selectByMouse: true
                        focus: true

                        onTextChanged: launcher.query = text

                        // ── Keyboard navigation ─────────
                        Keys.onEscapePressed:    launcher.hide()
                        Keys.onUpPressed:        launcher.moveSelection(-1)
                        Keys.onDownPressed:      launcher.moveSelection(1)
                        Keys.onReturnPressed:    launcher.launchSelected()
                        Keys.onEnterPressed:     launcher.launchSelected()
                        Keys.onPressed: function (e) {
                            if (e.key === Qt.Key_Tab) {
                                launcher.moveSelection(1)
                                e.accepted = true
                            }
                        }

                        // Placeholder
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            visible: searchField.text === ""
                            text: "Buscar aplicativos..."
                            font: searchField.font
                            color: launcher.colMuted
                        }
                    }
                }
            }

            // ── Result list ───────────────────────
            ListView {
                id: list
                Layout.fillWidth:  true
                Layout.fillHeight: true
                clip: true
                model: launcher.results
                currentIndex: launcher.selected
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds

                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

 delegate: Rectangle {
                    required property int index
                    required property var modelData

                    width:  list.width
                    height: 48
                    radius: 8
                    color: index === launcher.selected
                        ? Qt.rgba(0.73, 0.60, 0.97, 0.22)
                        : (itemMa.containsMouse ? Qt.rgba(0.48, 0.64, 0.97, 0.12)
                                                : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin:  12
                        anchors.rightMargin: 12
                        spacing: 12

                        Rectangle {
                            width: 3
                            height: 26
                            radius: 2
                            color: index === launcher.selected ? launcher.colPurple : "transparent"
                        }

                        // ── App icon ──────────
                        Image {
                            width:  28
                            height: 28
                            source: modelData.icon
                                ? "image://icon/" + modelData.icon
                                : ""
                            sourceSize.width:  28
                            sourceSize.height: 28
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            visible: modelData.icon !== ""
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                elide: Text.ElideRight
                                font.family: launcher.font
                                font.pixelSize: launcher.fsize + 1
                                font.bold: index === launcher.selected
                                color: launcher.colFg
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: modelData.comment ? modelData.comment : ""
                                elide: Text.ElideRight
                                font.family: launcher.font
                                font.pixelSize: launcher.fsize - 2
                                color: launcher.colMuted
                            }
                        }
                    }

                    MouseArea {
                        id: itemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered:  launcher.selected = index
                        onClicked:  launcher.launch(modelData)
                    }
                }

                // Empty list message
                Text {
                    anchors.centerIn: parent
                    visible: launcher.results.length === 0
                    text: appLoader.ready ? "No applications found"
                                          : "Loading applications..."
                    font.family: launcher.font
                    font.pixelSize: launcher.fsize
                    color: launcher.colMuted
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: launcher.results.length + " / " + appLoader.count + " apps"
                font.family: launcher.font
                font.pixelSize: launcher.fsize - 2
                color: launcher.colMuted
            }
        }
    }

    // ══════════════════════════════════════════════════════
    // DATA SOURCE
    // ══════════════════════════════════════════════════════
    AppLoader {
        id: appLoader
    }
}
