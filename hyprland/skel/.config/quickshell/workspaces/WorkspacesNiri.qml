import QtQuick
import QtQuick.Layouts
import Quickshell.WindowManager

// Niri has no dedicated Quickshell module, but it implements the generic
// ext-workspace-v1 protocol, which Quickshell.WindowManager wraps directly —
// no IPC polling needed, workspace state stays reactive for free.
//
// Unlike sway/Hyprland, niri creates workspaces dynamically instead of
// preallocating a fixed set, so this shows only the workspaces that actually
// exist rather than a static 1-9 grid.
RowLayout {
    id: root
    spacing: 6
    property var globalState

    readonly property var sorted: {
        const ws = WindowManager.windowsets.filter(w => w.shouldDisplay);
        ws.sort((a, b) => {
            const ac = a.coordinates, bc = b.coordinates;
            for (let i = 0; i < Math.max(ac.length, bc.length); i++) {
                const av = ac[i] ?? 0, bv = bc[i] ?? 0;
                if (av !== bv) return av - bv;
            }
            return 0;
        });
        return ws;
    }

    Repeater {
        model: root.sorted

        delegate: Rectangle {
            required property var modelData

            width: 22
            height: 22
            radius: 4
            color: modelData.active ? globalState.colPurple : Qt.rgba(0.48, 0.64, 0.97, 0.25)

            Text {
                anchors.centerIn: parent
                text: modelData.name
                color: modelData.active ? globalState.colBg : globalState.colBlue
                font { family: globalState.font; pixelSize: globalState.fsize; bold: true }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (modelData.canActivate) modelData.activate();
                }
            }
        }
    }
}
