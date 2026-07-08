// ══════════════════════════════════════════════════════
// example-integration.qml
// MINIMAL example of how to activate the launcher module
// from the main Quickshell configuration (shell.qml).
//
// This file is for demonstration only — copy the marked
// snippets into your shell.qml.
//
// To test in isolation:
//   qs -p ~/.config/quickshell/launcher/example-integration.qml
// ══════════════════════════════════════════════════════
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// (1) Import the launcher module using the relative path.
//     The "launcher" folder must sit alongside shell.qml.
import "launcher"

ShellRoot {

    // (2) Instantiate the Launcher once. It starts
    //     invisible and is shown via launcher.toggle().
    Launcher {
        id: appLauncher
        // The theme already uses the Tokyo Night palette by default;
        // but you can override any property:
        // colPurple: "#bb9af7"
        // terminal:  "foot"
    }

    // (3) Global shortcut via Hyprland to open/close.
    //     Equivalent to "bind = SUPER, D, ..." but handled here.
    GlobalShortcut {
        name: "launcher"
        description: "Open the app launcher"
        onPressed: appLauncher.toggle()
    }

    // (4) Bar button that opens the native launcher instead
    //     of calling "fuzzel" via Process.
    PanelWindow {
        anchors.top:  true
        anchors.left: true
        implicitHeight: 40
        implicitWidth:  60
        color: "#1a1b26"

        Rectangle {
            anchors.centerIn: parent
            width: 26; height: 26; radius: 6
            color: ma.containsMouse ? "#c7b3f9" : "#bb9af7"

            Text {
                anchors.centerIn: parent
                text: ""
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                color: "#1a1b26"
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                // ── BEFORE (called fuzzel) ──────────────
                // onClicked: {
                //     launcherProc.command = ["fuzzel"]
                //     launcherProc.running = true
                // }
                // ── AFTER (uses the native module) ──────────────
                onClicked: appLauncher.toggle()
            }
        }
    }
}
