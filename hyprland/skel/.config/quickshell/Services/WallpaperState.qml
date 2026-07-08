pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Global singleton: exposes the currently active wallpaper path, read
// from the same file written by Wallpaper.qml (persistProc/_persist) and
// by apply-saved-wallpaper.sh at Hyprland startup.
//
// Usage in other QML files (relative import, no qs.* alias):
//   import "../Services" as Services
//   Services.WallpaperState.hasWallpaper
//
// Does not write to the file normally (that is already done by
// Wallpaper.qml); only reacts to external changes via FileView.watchChanges.

Singleton {
    id: root

    // Must match stateFile in wallpaper/Wallpaper.qml and
    // STATE_FILE in wallpaper/apply-saved-wallpaper.sh.
    readonly property string statePath: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper/current"

    property string currentPath: ""
    readonly property bool hasWallpaper: currentPath !== ""

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        printErrors: false

        onLoaded: root.currentPath = text().trim()
        onLoadFailed: error => root.currentPath = ""
        onFileChanged: stateFile.reload()
    }
}
