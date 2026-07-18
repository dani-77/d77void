import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

RowLayout {
    spacing: 6
    property var globalState

    Process {
        id: wsProc
        running: false
    }

    Repeater {
        model: 9
        Rectangle {
            required property int index
            property int  wsId:     index + 1
            property var  ws:       Hyprland.workspaces.values.find(w => w.id === wsId)
            property bool isActive: Hyprland.focusedWorkspace !== null &&
                                    Hyprland.focusedWorkspace.id === wsId

            width: 22
            height: 22
            radius: 4
            color: isActive
                ? globalState.colPurple
                : (ws ? Qt.rgba(0.48, 0.64, 0.97, 0.25) : "transparent")

            Text {
                anchors.centerIn: parent
                text: parent.wsId
                color: parent.isActive ? globalState.colBg
                     : (parent.ws      ? globalState.colBlue : globalState.colMuted)
                font { family: globalState.font; pixelSize: globalState.fsize; bold: true }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    wsProc.command = ["hyprctl", "dispatch", "hl.dsp.focus({workspace = " + wsId + "})"]
                    wsProc.running = true
                }
            }
        }
    }
}
