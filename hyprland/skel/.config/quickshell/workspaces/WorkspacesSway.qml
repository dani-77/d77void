import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
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
            property var  ws:       I3.workspaces.values.find(w => w.number === wsId)
            property bool isActive: I3.focusedWorkspace !== null &&
                                    I3.focusedWorkspace.number === wsId

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
                    wsProc.command = ["swaymsg", "workspace", wsId.toString()]
                    wsProc.running = true
                }
            }
        }
    }
}
