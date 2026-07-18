// ══════════════════════════════════════════════════════
// GreeterSurface.qml
// Per-monitor greeter UI. Background is the same QML-drawn Backdrop
// used by the rest of quickshell-d77 (chevrons + d77 logo, no raster
// wallpaper needed) — see ../backdrop/Backdrop.qml. On top of it: a
// clock, and a login card (username, password, session picker) styled
// like lockscreen/LockSurface.qml so the greeter and the lockscreen
// look like the same product.
//
// Only the primary-screen instance (isPrimaryScreen) has interactive
// fields; other monitors just mirror the shared GreeterState read-only,
// the same approach the lockscreen uses for multi-monitor.
// ══════════════════════════════════════════════════════
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property bool isPrimaryScreen

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

    signal loginRequested
    signal poweroffRequested
    signal rebootRequested

    property bool sessionMenuOpen: false

    color: colBg

    // If a username was already remembered from the last successful login
    // (see GreeterState.lastUsername), it's pre-filled and there's nothing
    // to pick — send focus straight to the password field instead. Startup
    // timing is racy against GreeterState's async last-session file load,
    // so this is checked both here and reactively below.
    Component.onCompleted: {
        if (isPrimaryScreen)
            (GreeterState.lastUsername !== "" ? passwordBox : usernameBox).forceActiveFocus();
    }

    Connections {
        target: GreeterState
        function onLastUsernameChanged() {
            if (root.isPrimaryScreen && GreeterState.lastUsername !== "")
                passwordBox.forceActiveFocus();
        }
    }

    // ── Background: the QML-drawn d77 backdrop (chevrons + logo) ──
    GreeterBackdrop {
        anchors.fill: parent
        colBg:     root.colBg
        colFg:     root.colFg
        colPurple: root.colPurple
    }

    // ── Clock ───────────────────────────────────────────
    Text {
        id: clock
        property var date: new Date()

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 90
        }

        renderType: Text.NativeRendering
        font.family: root.font
        font.pixelSize: 88
        font.bold: true
        color: root.colBlue

        text: {
            const h = date.getHours().toString().padStart(2, "0");
            const m = date.getMinutes().toString().padStart(2, "0");
            return `${h}:${m}`;
        }

        Timer {
            running: true
            repeat: true
            interval: 1000
            onTriggered: clock.date = new Date()
        }
    }

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

    // ── Login card ──────────────────────────────────────
    Rectangle {
        id: card
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.verticalCenter
            topMargin: 30
        }
        width: 380
        implicitHeight: cardLayout.implicitHeight + 48
        radius: 14
        color: Qt.darker(root.colBg, 1.3)
        border.color: root.colMuted
        border.width: 1

        ColumnLayout {
            id: cardLayout
            anchors {
                fill: parent
                margins: 24
            }
            spacing: 12

            // Username
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 48
                radius: 10
                color: Qt.darker(root.colBg, 1.15)
                border.color: usernameBox.activeFocus ? root.colPurple : root.colMuted
                border.width: 2

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: "󰀄"
                        font.family: root.font
                        font.pixelSize: root.fsize + 4
                        color: root.colPurple
                    }

                    TextInput {
                        id: usernameBox
                        Layout.fillWidth: true
                        clip: true
                        enabled: root.isPrimaryScreen && !GreeterState.unlocking
                        text: GreeterState.username
                        color: root.colFg
                        font.family: root.font
                        font.pixelSize: root.fsize + 2
                        selectionColor: root.colPurple
                        selectByMouse: true
                        verticalAlignment: TextInput.AlignVCenter

                        onTextChanged: GreeterState.username = text
                        onAccepted: passwordBox.forceActiveFocus()

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            visible: usernameBox.text === ""
                            text: "Username..."
                            font: usernameBox.font
                            color: root.colMuted
                        }
                    }
                }
            }

            // Password
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 48
                radius: 10
                color: Qt.darker(root.colBg, 1.15)
                border.color: passwordBox.activeFocus ? root.colPurple : root.colMuted
                border.width: 2

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
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
                        enabled: root.isPrimaryScreen && !GreeterState.unlocking
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        inputMethodHints: Qt.ImhSensitiveData
                        text: GreeterState.password
                        color: root.colFg
                        font.family: root.font
                        font.pixelSize: root.fsize + 2
                        selectionColor: root.colPurple
                        selectByMouse: true
                        verticalAlignment: TextInput.AlignVCenter

                        onTextChanged: GreeterState.password = text
                        onAccepted: root.loginRequested()

                        Keys.onTabPressed: {
                            event.accepted = true;
                            sessionButton.forceActiveFocus();
                        }

                        // Editing a TextInput breaks its declarative `text:`
                        // binding (Qt writes `text` imperatively on every
                        // keystroke), so GreeterState.password getting
                        // cleared after a failed login wouldn't otherwise
                        // be reflected here — force it back in sync.
                        Connections {
                            target: GreeterState
                            function onPasswordChanged() {
                                if (passwordBox.text !== GreeterState.password)
                                    passwordBox.text = GreeterState.password;
                            }
                        }

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

            // Session picker
            Rectangle {
                id: sessionButton
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 10
                color: sessionMa.containsMouse ? Qt.darker(root.colBg, 1.05) : Qt.darker(root.colBg, 1.15)
                border.color: (root.sessionMenuOpen || sessionButton.activeFocus) ? root.colPurple : root.colMuted
                border.width: 2
                enabled: root.isPrimaryScreen && !GreeterState.unlocking

                Keys.onUpPressed: {
                    if (GreeterState.sessionList.length > 0)
                        GreeterState.currentSessionIndex = (GreeterState.currentSessionIndex - 1 + GreeterState.sessionList.length) % GreeterState.sessionList.length;
                }
                Keys.onDownPressed: {
                    if (GreeterState.sessionList.length > 0)
                        GreeterState.currentSessionIndex = (GreeterState.currentSessionIndex + 1) % GreeterState.sessionList.length;
                }
                Keys.onReturnPressed: root.loginRequested()
                Keys.onEnterPressed: root.loginRequested()

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: GreeterState.sessionList.length > 0 ? (GreeterState.sessionList[GreeterState.currentSessionIndex] || GreeterState.sessionList[0]) : "No sessions found"
                        color: root.colFg
                        font.family: root.font
                        font.pixelSize: root.fsize
                    }

                    Text {
                        text: root.sessionMenuOpen ? "" : ""
                        font.family: root.font
                        font.pixelSize: root.fsize
                        color: root.colMuted
                    }
                }

                MouseArea {
                    id: sessionMa
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: parent.enabled && GreeterState.sessionList.length > 0
                    onClicked: root.sessionMenuOpen = !root.sessionMenuOpen
                }
            }

            // Login button
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: 48
                radius: 10
                enabled: root.isPrimaryScreen && !GreeterState.unlocking && usernameBox.text !== "" && passwordBox.text !== "" && GreeterState.sessionList.length > 0
                color: loginMa.containsMouse && enabled ? Qt.lighter(root.colPurple, 1.15) : (enabled ? root.colPurple : root.colMuted)

                Text {
                    anchors.centerIn: parent
                    text: GreeterState.unlocking ? "..." : "Login"
                    font.family: root.font
                    font.pixelSize: root.fsize + 1
                    font.bold: true
                    color: root.colBg
                }

                MouseArea {
                    id: loginMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: if (parent.enabled)
                        root.loginRequested();
                }
            }

            // Feedback
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: GreeterState.pamState !== ""
                text: GreeterState.pamState === "fail" ? "󰀦  Incorrect username or password" : "󰀦  Login failed, try again"
                font.family: root.font
                font.pixelSize: root.fsize
                color: root.colRed
            }
        }
    }

    // ── Session dropdown popup ──────────────────────────
    // sessionButton lives deep inside card's ColumnLayout, so it isn't a
    // parent/sibling of sessionPopup (a direct child of root) — anchors
    // require that relationship, so position via mapToItem instead.
    Rectangle {
        id: sessionPopup
        visible: root.sessionMenuOpen
        x: sessionButton.mapToItem(root, 0, 0).x
        y: sessionButton.mapToItem(root, 0, sessionButton.height).y + 6
        width: sessionButton.width
        implicitHeight: Math.min(sessionList.count, 6) * 40 + 8
        radius: 10
        color: Qt.darker(root.colBg, 1.4)
        border.color: root.colMuted
        border.width: 1
        z: 10

        ListView {
            id: sessionList
            anchors.fill: parent
            anchors.margins: 4
            clip: true
            model: GreeterState.sessionList

            delegate: Rectangle {
                required property string modelData
                required property int index

                width: sessionList.width
                height: 40
                radius: 8
                color: itemMa.containsMouse ? Qt.darker(root.colBg, 1.1) : "transparent"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    text: modelData
                    color: index === GreeterState.currentSessionIndex ? root.colPurple : root.colFg
                    font.family: root.font
                    font.pixelSize: root.fsize
                }

                MouseArea {
                    id: itemMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        GreeterState.currentSessionIndex = index;
                        root.sessionMenuOpen = false;
                    }
                }
            }
        }
    }

    // Click-away area to close the session dropdown.
    MouseArea {
        anchors.fill: parent
        visible: root.sessionMenuOpen
        z: 9
        onClicked: root.sessionMenuOpen = false
    }

    // ── Power controls (bottom-left) ─────────────────────
    // Kept just under the logo's bottom edge (48px margin, 180px tall —
    // see GreeterBackdrop.qml) rather than overlapping it: margin + size
    // here stays comfortably under 48.
    RowLayout {
        anchors {
            left: parent.left
            bottom: parent.bottom
            margins: 14
        }
        spacing: 6
        visible: root.isPrimaryScreen

        Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: 8
            color: poweroffMa.containsMouse ? Qt.rgba(0.97, 0.46, 0.56, 0.2) : Qt.darker(root.colBg, 1.15)
            border.color: root.colMuted
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰐥"
                font.family: root.font
                font.pixelSize: root.fsize
                color: root.colRed
            }

            MouseArea {
                id: poweroffMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.poweroffRequested()
            }
        }

        Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: 8
            color: rebootMa.containsMouse ? Qt.darker(root.colBg, 1.05) : Qt.darker(root.colBg, 1.15)
            border.color: root.colMuted
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰜉"
                font.family: root.font
                font.pixelSize: root.fsize
                color: root.colBlue
            }

            MouseArea {
                id: rebootMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.rebootRequested()
            }
        }
    }
}
