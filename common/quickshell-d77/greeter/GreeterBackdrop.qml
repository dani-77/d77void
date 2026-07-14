// ══════════════════════════════════════════════════════
// GreeterBackdrop.qml
// The same QML-drawn background as ../backdrop/Backdrop.qml (Tokyo
// Night chevrons + d77 logo), vendored into greeter/ instead of
// imported across the config-root boundary.
//
// Why a copy instead of `import "../backdrop"`: greetd points `qs -p`
// directly at this greeter/ folder, which becomes its own self-contained
// config root — Quickshell doesn't resolve relative imports that climb
// back out of that root (`../backdrop` from inside it fails to load at
// runtime, even though the file exists on disk). Since this folder also
// needs to be copied out to /etc/greetd/... standalone on install anyway
// (see README.md), keeping the artwork local avoids depending on the
// rest of the repo being deployed alongside it. Unlike the original,
// this is always visible — the greeter has no "wallpaper set" concept
// to hide itself for.
// ══════════════════════════════════════════════════════
import QtQuick

Item {
    id: root
    clip: true

    property color colBg:     "#1a1b26"
    property color colFg:     "#a9b1d6"
    property color colPurple: "#bb9af7"

    // Keep in sync with ../backdrop/assets/d77-logo.svg if you change the logo.
    property string logoSource: "assets/d77-logo.svg"

    Rectangle {
        anchors.fill: parent
        color: root.colBg
    }

    // Chevron 1 (darker, behind)
    Rectangle {
        x: root.width * 0.68
        y: -root.height * 0.3
        width: root.width * 0.8
        height: root.height * 1.6
        color: Qt.darker(root.colPurple, 2.2)
        rotation: 35
    }

    // Chevron 2 (colPurple, overlaid in front)
    Rectangle {
        x: root.width * 0.84
        y: -root.height * 0.2
        width: root.width * 0.4
        height: root.height * 1.3
        color: Qt.darker(root.colPurple, 1.4)
        rotation: 35
    }

    // Logo in the bottom-left corner, at ~25% opacity.
    Image {
        anchors.left:   parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 48
        width:  180
        height: width
        fillMode:     Image.PreserveAspectFit
        smooth:       true
        mipmap:       true
        asynchronous: true
        source:  Qt.resolvedUrl(root.logoSource)
        opacity: 0.25
        visible: status === Image.Ready
    }
}
