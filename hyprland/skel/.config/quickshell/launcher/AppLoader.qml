// ══════════════════════════════════════════════════════
// AppLoader.qml
// Join DesktopDirScanner and desktopParser.js to
// produce a list of ready to use applications.
// ══════════════════════════════════════════════════════
import QtQuick
import Quickshell
import "desktopParser.js" as Parser

Item {
    id: loader

    // ── Complet list of apps (objects array JS) ──────
    // Each item: { name, exec, icon, comment, categories,
    //              terminal, noDisplay, hidden, isApp }
    property var apps: []

    // Quantity of loaded apps
    readonly property int count: apps.length

    // Indicates whether there has already been at least one run
    property bool ready: false

    // ── Signals ────────────────────────────────────────────
    signal loaded()

    // ── Reload apps list ──────────────────
    function reload() {
        scanner.scan()
    }

    // ── Filter apps by query (delegates to parser) ───
    function filter(query) {
        return Parser.filterApps(loader.apps, query)
    }

    // ── Scanner that feeds the parser ─────────────────────
    DesktopDirScanner {
        id: scanner
        onScanned: function (raw) {
            loader.apps  = Parser.parseEntries(raw)
            loader.ready = true
            loader.loaded()
        }
    }

    // Load as soon as the the component is ready
    Component.onCompleted: reload()
}
