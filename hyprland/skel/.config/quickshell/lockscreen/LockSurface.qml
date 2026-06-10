// ══════════════════════════════════════════════════════
// LockSurface.qml
// Lockscreen UI (one instance per monitor). Displays
// the clock, date, and password field. The authentication
// logic resides in the shared LockContext.
//
// The style aligns with the Tokyo Night color palette of the rest
//  of the project. (Same approach as the launcher: Rectangle + TextInput,
//  without depending on QtQuick.Controls).
// ══════════════════════════════════════════════════════
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland

Rectangle {
    id: root

    required property LockContext context

    // ══════════════════════════════════════════════════════
    // THEME (Tokyo Night)
    // ══════════════════════════════════════════════════════
    property color colBg:     "#1a1b26"
    property color colFg:     "#a9b1d6"
    property color colMuted:  "#444b6a"
    property color colBlue:   "#7aa2f7"
    property color colPurple: "#bb9af7"
    property color colRed:    "#f7768e"
    property string font:     "JetBrainsMono Nerd Font"
    property int    fsize:    13

    color: colBg

    // Focus on the password field as soon as the surface appears.
    Component.onCompleted: passwordBox.forceActiveFocus()

    // ── Clock ───────────────────────────────────────────
    Text {
        id: clock
        property var date: new Date()

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 120
        }

        renderType: Text.NativeRendering
        font.family: root.font
        font.pixelSize: 96
        font.bold: true
        color: root.colBlue

        text: {
            const h = date.getHours().toString().padStart(2, "0")
            const m = date.getMinutes().toString().padStart(2, "0")
            return `${h}:${m}`
        }

        Timer {
            running: true
            repeat: true
            interval: 1000
            onTriggered: clock.date = new Date()
        }
    }

    // ── Date ──────────────────────────────────────────────
    Text {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: clock.bottom
            topMargin: 8
        }
        font.family: root.font
        font.pixelSize: root.fsize + 4
        color: root.colMuted
        text: Qt.formatDateTime(clock.date, "dddd, dd MMMM yyyy")
    }

    // ── Authentication box ─────────────────────────────
    ColumnLayout {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.verticalCenter
            topMargin: 40
        }
        spacing: 12

        RowLayout {
            spacing: 10
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                Layout.preferredWidth: 360
                implicitHeight: 48
                radius: 10
                color: Qt.darker(root.colBg, 1.3)
                border.color: passwordBox.activeFocus ? root.colPurple : root.colMuted
                border.width: 2

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin:  14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: "󰌾"
                        font.family: root.font
                        font.pixelSize: root.fsize + 4
                        color: root.colPurple
                    }

                    TextInput {
                        id: passwordBox
                        Layout.fillWidth: true
                        clip: true
                        focus: true
                        enabled: !root.context.unlockInProgress
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        inputMethodHints: Qt.ImhSensitiveData
                        color: root.colFg
                        font.family: root.font
                        font.pixelSize: root.fsize + 2
                        selectionColor: root.colPurple
                        selectByMouse: true
                        verticalAlignment: TextInput.AlignVCenter

                        onTextChanged: root.context.currentText = text
                        onAccepted: root.context.tryUnlock()

                        Connections {
                            target: root.context
                            function onCurrentTextChanged() {
                                if (passwordBox.text !== root.context.currentText)
                                    passwordBox.text = root.context.currentText
                            }
                        }

                        // Placeholder
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            visible: passwordBox.text === ""
                            text: "Password..."
                            font: passwordBox.font
                            color: root.colMuted
                        }
                    }
                }
            }

            Rectangle {
                implicitWidth: 110
                implicitHeight: 48
                radius: 10
                enabled: !root.context.unlockInProgress && root.context.currentText !== ""
                color: unlockMa.containsMouse && enabled
                    ? Qt.lighter(root.colPurple, 1.15)
                    : (enabled ? root.colPurple : root.colMuted)

                Text {
                    anchors.centerIn: parent
                    text: root.context.unlockInProgress ? "..." : "Unlock"
                    font.family: root.font
                    font.pixelSize: root.fsize + 1
                    font.bold: true
                    color: root.colBg
                }

                MouseArea {
                    id: unlockMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        if (parent.enabled) root.context.tryUnlock()
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.context.showFailure
            text: "󰀦  Incorrect password"
            font.family: root.font
            font.pixelSize: root.fsize
            color: root.colRed
        }
    }
}
