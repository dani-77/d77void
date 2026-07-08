import QtQuick
import Quickshell
import Quickshell.Wayland

// One instance per screen (Variants over Quickshell.screens). Sits on the
// "Bottom" layer-shell layer — just ABOVE the "Background" layer where
// hyprpaper draws the real wallpaper. This avoids two wlr-layer-shell
// clients competing for the same layer (which would cause flicker /
// unpredictable z-order).
//
// When there is no wallpaper: only this (the Backdrop) is visible.
// When there is a wallpaper: hyprpaper draws beneath it, and the Backdrop
// hides itself (visible: false inside), letting the real wallpaper show.

Variants {
    id: root

    // ══════════════════════════════════════════════════════
    // THEME (Tokyo Night) — overridden from shell.qml (g.*)
    // ══════════════════════════════════════════════════════
    property color colBg:     "#1a1b26"
    property color colFg:     "#a9b1d6"
    property color colPurple: "#bb9af7"

    model: Quickshell.screens

    PanelWindow {
        id: panel
        required property var modelData
        screen: modelData

        WlrLayershell.layer:         WlrLayer.Bottom
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace:     "quickshell-backdrop"

        anchors {
            top:    true
            bottom: true
            left:   true
            right:  true
        }

        color: "transparent"

        // Do not intercept clicks/focus — this is purely background decoration.
        mask: Region {
            item: Item {}
        }

        Backdrop {
            anchors.fill: parent
            colBg:     root.colBg
            colFg:     root.colFg
            colPurple: root.colPurple
        }
    }
}
