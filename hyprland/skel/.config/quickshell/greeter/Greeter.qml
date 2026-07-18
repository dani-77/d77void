// ══════════════════════════════════════════════════════
// Greeter.qml
// Native greetd greeter for quickshell-d77. Scans
// /usr/share/{wayland-sessions,xsessions} (+ XDG_DATA_DIRS and the
// user's ~/.local/share equivalents) for session *.desktop files,
// drives the greetd IPC (Quickshell.Services.Greetd) through
// username/password entry, and launches the chosen session on success.
//
// X11 sessions are launched wrapped in `startx /usr/bin/env <exec>`
// (the same default tuigreet uses for --xsession-wrapper) because
// greetd never starts an Xorg server on its own — it only execs the
// command from the .desktop file directly on the VT. Wayland sessions
// (compositor binaries) are exec'd as-is.
// ══════════════════════════════════════════════════════
import QtQuick
import QtQml.Models
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd

Scope {
    id: root

    // ══════════════════════════════════════════════════════
    // THEME (Tokyo Night) — overridable, mirrors g.* in shell.qml
    // ══════════════════════════════════════════════════════
    property color colBg:     "#1a1b26"
    property color colFg:     "#a9b1d6"
    property color colMuted:  "#444b6a"
    property color colBlue:   "#7aa2f7"
    property color colPurple: "#bb9af7"
    property color colRed:    "#f7768e"
    property string font:     "JetBrainsMono Nerd Font"
    property int    fsize:    13

    // ══════════════════════════════════════════════════════
    // SESSION DISCOVERY (X11 + Wayland)
    // ══════════════════════════════════════════════════════
    function encodeFileUrl(path) {
        if (!path)
            return "";
        return "file://" + path.split("/").map(s => encodeURIComponent(s)).join("/");
    }

    readonly property var sessionDirs: {
        const home = Quickshell.env("HOME") || "";
        const xdgDataDirs = Quickshell.env("XDG_DATA_DIRS") || "";
        const dirs = [{
            "dir": "/usr/share/wayland-sessions",
            "type": "wayland"
        }, {
            "dir": "/usr/share/xsessions",
            "type": "x11"
        }, {
            "dir": "/usr/local/share/wayland-sessions",
            "type": "wayland"
        }, {
            "dir": "/usr/local/share/xsessions",
            "type": "x11"
        }];

        xdgDataDirs.split(":").forEach(d => {
            if (!d)
                return;
            dirs.push({
                "dir": d + "/wayland-sessions",
                "type": "wayland"
            });
            dirs.push({
                "dir": d + "/xsessions",
                "type": "x11"
            });
        });

        if (home) {
            dirs.push({
                "dir": home + "/.local/share/wayland-sessions",
                "type": "wayland"
            });
            dirs.push({
                "dir": home + "/.local/share/xsessions",
                "type": "x11"
            });
        }

        // Reversed so user-local dirs are scanned first: _addSession()
        // guards on session name, so whichever copy is found first wins.
        return dirs.reverse();
    }

    property var _pendingFiles: ({})
    property int _pendingCount: 0

    function _addSession(path, name, exec, type) {
        if (!name || !exec || GreeterState.sessionList.includes(name))
            return;
        // dwl only hosts this greeter itself (see assets/greet-dwl.sh) — its
        // own .desktop entry, if installed, isn't something to log into.
        // Exec= is often wrapped (e.g. "dbus-launch dwl"), so check every
        // token rather than just the first.
        const execTokens = exec.trim().split(/\s+/).map(t => t.split("/").pop().toLowerCase());
        if (name.trim().toLowerCase() === "dwl" || execTokens.includes("dwl"))
            return;
        GreeterState.sessionList = GreeterState.sessionList.concat([name]);
        GreeterState.sessionExecs = GreeterState.sessionExecs.concat([exec]);
        GreeterState.sessionPaths = GreeterState.sessionPaths.concat([path]);
        GreeterState.sessionTypes = GreeterState.sessionTypes.concat([type]);
    }

    function _parseDesktopFile(content, path, type) {
        let name = "";
        let exec = "";
        const lines = content.split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (!name && line.startsWith("Name="))
                name = line.substring(5).trim();
            else if (!exec && line.startsWith("Exec="))
                exec = line.substring(5).trim();
            if (name && exec)
                break;
        }
        _addSession(path, name, exec, type);
    }

    function _loadDesktopFile(filePath, type) {
        if (_pendingFiles[filePath])
            return;
        _pendingFiles[filePath] = true;
        _pendingCount++;
        desktopFileLoader.createObject(root, {
            "filePath": filePath,
            "sessionType": type
        });
    }

    function _onFileLoaded() {
        _pendingCount--;
        if (_pendingCount === 0)
            Qt.callLater(_finalizeSessionSelection);
    }

    function _finalizeSessionSelection() {
        if (GreeterState.sessionList.length === 0)
            return;
        if (GreeterState.currentSessionIndex >= GreeterState.sessionList.length)
            GreeterState.currentSessionIndex = 0;
    }

    Component {
        id: desktopFileLoader

        FileView {
            id: fv
            property string filePath: ""
            property string sessionType: ""
            path: filePath

            onLoaded: {
                root._parseDesktopFile(text(), filePath, sessionType);
                root._onFileLoaded();
                fv.destroy();
            }
            onLoadFailed: {
                root._onFileLoaded();
                fv.destroy();
            }
        }
    }

    // Instantiator (not Repeater): root is a Scope, not an Item, and
    // QtQuick's Repeater silently creates zero delegates when its parent
    // isn't an Item — the session scan would never run and the session
    // list would stay empty regardless of which compositor hosts it.
    Instantiator {
        model: root.sessionDirs

        Item {
            required property var modelData

            FolderListModel {
                folder: root.encodeFileUrl(modelData.dir)
                nameFilters: ["*.desktop"]
                showDirs: false
                showDotAndDotDot: false

                onStatusChanged: {
                    if (status !== FolderListModel.Ready)
                        return;
                    for (let i = 0; i < count; i++) {
                        let fp = get(i, "filePath");
                        if (fp.startsWith("file://"))
                            fp = fp.substring(7);
                        root._loadDesktopFile(fp, modelData.type);
                    }
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════
    // GREETD IPC
    // ══════════════════════════════════════════════════════
    function tryLogin() {
        if (GreeterState.unlocking || Greetd.state !== GreetdState.Inactive)
            return;
        if (GreeterState.sessionList.length === 0 || !GreeterState.username)
            return;
        GreeterState.pamState = "";
        GreeterState.unlocking = true;
        Greetd.createSession(GreeterState.username);
        authTimeout.restart();
    }

    function _resetAfterFailure() {
        authTimeout.stop();
        GreeterState.unlocking = false;
        GreeterState.password = "";
    }

    // Safety net: PAM/greetd should always answer, but if the socket ever
    // hangs there would otherwise be no way out of "unlocking" state.
    Timer {
        id: authTimeout
        interval: 20000
        onTriggered: {
            root._resetAfterFailure();
            GreeterState.pamState = "error";
            Greetd.cancelSession();
        }
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            authTimeout.restart();
            if (responseRequired)
                Greetd.respond(GreeterState.password);
            else
                Greetd.respond("");
        }

        function onAuthFailure(message) {
            root._resetAfterFailure();
            GreeterState.pamState = "fail";
        }

        function onError(error) {
            root._resetAfterFailure();
            GreeterState.pamState = "error";
        }

        function onReadyToLaunch() {
            authTimeout.stop();
            const idx = GreeterState.currentSessionIndex;
            const execCmd = GreeterState.sessionExecs[idx];
            const sessionType = GreeterState.sessionTypes[idx];
            if (!execCmd) {
                root._resetAfterFailure();
                GreeterState.pamState = "error";
                Greetd.cancelSession();
                return;
            }
            GreeterState.rememberLastLogin(GreeterState.username, GreeterState.sessionList[idx]);
            const args = execCmd.trim().split(/\s+/);
            if (sessionType === "x11")
                Greetd.launch(["startx", "/usr/bin/env"].concat(args), ["XDG_SESSION_TYPE=x11"]);
            else
                Greetd.launch(args, ["XDG_SESSION_TYPE=wayland"]);
        }
    }

    // ══════════════════════════════════════════════════════
    // POWER CONTROLS
    // Mirrors shell.qml's loginctl/systemctl fallback. The greeter's own
    // compositor instance is the only active seat session at this point,
    // so logind's default polkit rules (allow_active) let reboot/poweroff
    // succeed without a password prompt — the same way GDM/SDDM's own
    // greeter power buttons work.
    // ══════════════════════════════════════════════════════
    function _sessionCmd(action) {
        return ["sh", "-c", "loginctl " + action + " 2>&1 || systemctl " + action + " 2>&1"];
    }

    Process {
        id: rebootProc
        command: root._sessionCmd("reboot")
        running: false
    }

    Process {
        id: shutdownProc
        command: root._sessionCmd("poweroff")
        running: false
    }

    // ══════════════════════════════════════════════════════
    // ONE SURFACE PER MONITOR — only the first screen gets keyboard
    // focus and interactive fields; other screens just mirror the
    // same background + read-only state (matches the multi-monitor
    // approach already used by the lockscreen).
    // ══════════════════════════════════════════════════════
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

            required property var modelData
            readonly property bool isPrimaryScreen: modelData === Quickshell.screens[0]

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: panel.isPrimaryScreen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell-greeter"

            GreeterSurface {
                anchors.fill: parent
                isPrimaryScreen: panel.isPrimaryScreen
                colBg:     root.colBg
                colFg:     root.colFg
                colMuted:  root.colMuted
                colBlue:   root.colBlue
                colPurple: root.colPurple
                colRed:    root.colRed
                font:      root.font
                fsize:     root.fsize
                onLoginRequested:     root.tryLogin()
                onPoweroffRequested:  shutdownProc.running = true
                onRebootRequested:    rebootProc.running = true
            }
        }
    }
}
