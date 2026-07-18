pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Global singleton: shared login state, read/written by Greeter.qml
// (the Greetd IPC + session scanner) and rendered by every per-monitor
// GreeterSurface instance.
//
// Usage (relative import, no qs.* alias):
//   import "../Services" as Services   // pattern used elsewhere in the repo
//   GreeterState.username

Singleton {
    id: root

    property string username: ""
    property string password: ""
    property string pamState: ""   // "" | "authenticating" | "fail" | "error"
    property bool   unlocking: false

    // One entry per discovered *.desktop session, same index across all
    // four arrays. sessionTypes[i] is "wayland" or "x11" depending on
    // whether the entry came from a wayland-sessions or xsessions dir —
    // this drives the startx wrapping done in Greeter.qml on launch.
    property var sessionList:  []
    property var sessionExecs: []
    property var sessionPaths: []
    property var sessionTypes: []
    property int currentSessionIndex: 0

    // ══════════════════════════════════════════════════════
    // LAST LOGIN (persisted across boots)
    // Remembers the username/session from the last *successful* login
    // (see Greeter.qml's onReadyToLaunch → rememberLastLogin()) so
    // returning users don't have to retype/reselect every time. Read via
    // JsonAdapter (no shell involved, so an arbitrary username can't
    // reach a shell command line) into a small JSON file under
    // $HOME/.cache — for the "greeter" system user that's /var/lib/greeter
    // per the Installation steps in README.md.
    readonly property string lastUsername:    lastSessionAdapter.username
    readonly property string lastSessionName: lastSessionAdapter.session

    function rememberLastLogin(user, sessionName) {
        lastSessionAdapter.username = user;
        lastSessionAdapter.session = sessionName;
        lastSessionFile.writeAdapter();
    }

    // Applies the saved session by name (not index — discovery order
    // isn't stable across boots) as soon as both the session scan and the
    // saved-state file have loaded, whichever finishes last.
    function _applySavedSession() {
        if (sessionList.length === 0 || lastSessionName === "")
            return;
        const idx = sessionList.indexOf(lastSessionName);
        if (idx !== -1)
            currentSessionIndex = idx;
    }
    onSessionListChanged: _applySavedSession()
    onLastSessionNameChanged: _applySavedSession()

    // Prefill the username field once, the first time a saved one shows
    // up — after that, GreeterSurface's TextInput owns `username`.
    onLastUsernameChanged: {
        if (username === "" && lastUsername !== "")
            username = lastUsername;
    }

    readonly property string _stateDir: (Quickshell.env("HOME") || "/tmp") + "/.cache/quickshell/greeter"

    // Ensures _stateDir exists before the first writeAdapter() call. Runs
    // once at startup, well before a login can complete, so there's no
    // ordering dependency to wait on.
    Process {
        running: true
        command: ["mkdir", "-p", root._stateDir]
    }

    FileView {
        id: lastSessionFile
        path: root._stateDir + "/last-session.json"
        printErrors: false

        JsonAdapter {
            id: lastSessionAdapter
            property string username: ""
            property string session: ""
        }
    }

    function reset() {
        password = "";
        pamState = "";
        unlocking = false;
    }
}
