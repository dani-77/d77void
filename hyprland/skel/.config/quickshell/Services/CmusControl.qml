pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Global singleton: cmus control + status, shared by dashboard/Dashboard.qml
// and musicpicker/MusicPicker.qml. Port of cmus_control.py from fabric-d77 —
// pulled into its own service once a second module (the music picker)
// needed the same cmus-remote plumbing.
//
// Usage in other QML files (relative import, no qs.* alias):
//   import "../Services" as Services
//   Services.CmusControl.running / .status / .track
//   Services.CmusControl.refresh() / .prev() / .togglePlay() / .next()
//   Services.CmusControl.skipAlbum(+1|-1)
//   Services.CmusControl.startHeadless()
//   Services.CmusControl.playAlbum(path)

Singleton {
    id: root

    // ══════════════════════════════════════════════════════
    // STATE (mirrors dashboard cmusRunning/cmusStatus/cmusTrack)
    // ══════════════════════════════════════════════════════
    property bool   running: false
    property string status:  "stopped"
    property string track:   "—"

    // ══════════════════════════════════════════════════════
    // CMUS ENVIRONMENT (XDG_RUNTIME_DIR/HOME) — read from cmus itself
    // ══════════════════════════════════════════════════════
    // A tmux/screen-hosted cmus can outlive a logout/compositor switch, so
    // its actual XDG_RUNTIME_DIR/HOME can end up different from ours by the
    // time we go to run cmus-remote — we can't just assume our own
    // environment still matches. Instead these are discovered by reading
    // the running cmus process's own environment (/proc/<pid>/environ) and
    // applied to every cmus-remote call below via `environment: root.cmusEnv`.
    // Empty until the first successful discovery, in which case cmus-remote
    // just inherits our own environment as before.
    property string _cmusRuntimeDir: ""
    property string _cmusHome:       ""
    readonly property var cmusEnv: _cmusRuntimeDir
        ? ({ XDG_RUNTIME_DIR: _cmusRuntimeDir, HOME: _cmusHome || Quickshell.env("HOME") })
        : ({})

    function _discoverCmusEnv() {
        _envDiscoverProc.running = true
    }

    Process {
        id: _envDiscoverProc
        running: false
        command: ["sh", "-c",
            "pid=$(pgrep -x cmus 2>/dev/null | head -n1); " +
            "[ -z \"$pid\" ] && pid=$(ps -eo pid,comm 2>/dev/null | awk '$2==\"cmus\"{print $1; exit}'); " +
            "[ -n \"$pid\" ] && tr '\\0' '\\n' < /proc/$pid/environ 2>/dev/null | grep -E '^(XDG_RUNTIME_DIR|HOME)='"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                text.split("\n").forEach(line => {
                    if (line.startsWith("XDG_RUNTIME_DIR="))
                        root._cmusRuntimeDir = line.slice("XDG_RUNTIME_DIR=".length)
                    else if (line.startsWith("HOME="))
                        root._cmusHome = line.slice("HOME=".length)
                })
            }
        }
        onExited: root.refresh()
    }

    Component.onCompleted: root._discoverCmusEnv()

    // Parses `cmus-remote -Q` output. Shared by refresh() and the
    // album-skip queries below, which all need the same status/tag lines.
    function _parseQuery(text) {
        var status = "stopped", artist = "", title = "", album = ""
        text.split("\n").forEach(line => {
            if (line.startsWith("status "))
                status = line.slice(7).trim()
            else if (line.startsWith("tag artist "))
                artist = line.slice(11).trim()
            else if (line.startsWith("tag title "))
                title = line.slice(10).trim()
            else if (line.startsWith("tag album "))
                album = line.slice(10).trim()
        })
        return { status: status, artist: artist, title: title, album: album }
    }

    // ── Status polling ──────────────────────────────────────
    function refresh() {
        _queryProc.running = true
    }

    Process {
        id: _queryProc
        running: false
        command: ["cmus-remote", "-Q"]
        environment: root.cmusEnv
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "") {
                    root.running = false
                    root.status  = "stopped"
                    root.track   = "—"
                    return
                }
                var q = root._parseQuery(text)
                var track = (q.artist && q.title) ? (q.artist + " — " + q.title) : (q.title || "—")
                if (track.length > 42) track = track.slice(0, 40) + "…"
                root.running = true
                root.status  = q.status
                root.track   = track
            }
        }
        onExited: function (code) {
            if (code !== 0) {
                root.running = false
                root.status  = "stopped"
                root.track   = "—"
                // Cached env may be stale (e.g. cmus was restarted outside
                // startHeadless()) — rediscover so the next refresh() works.
                root._discoverCmusEnv()
            }
        }
    }

    // ── Track controls ──────────────────────────────────────
    function prev()       { _prevProc.running = true }
    function togglePlay() { _toggleProc.running = true }
    function next()       { _nextProc.running = true }

    Process { id: _prevProc;   command: ["cmus-remote", "-r"]; environment: root.cmusEnv; running: false; onExited: root.refresh() }
    Process { id: _toggleProc; command: ["cmus-remote", "-u"]; environment: root.cmusEnv; running: false; onExited: root.refresh() }
    Process { id: _nextProc;   command: ["cmus-remote", "-n"]; environment: root.cmusEnv; running: false; onExited: root.refresh() }

    // ── Headless start (tmux, falling back to screen) ───────
    // XDG_RUNTIME_DIR/HOME are passed explicitly here from our own
    // environment — the only point where there's no running cmus process
    // yet to read them back from. Once cmus is up, _startRestartTimer
    // rediscovers its actual environment (see above) and every cmus-remote
    // call afterwards follows that instead of assuming it still matches ours.
    function startHeadless() {
        _startProc.running = true
    }

    Process {
        id: _startProc
        running: false
        command: ["sh", "-c",
            'tmux kill-session -t cmus >/dev/null 2>&1; ' +
            'command -v tmux >/dev/null 2>&1 && { tmux new-session -d -s cmus "XDG_RUNTIME_DIR=' + Quickshell.env("XDG_RUNTIME_DIR") + ' HOME=' + Quickshell.env("HOME") + ' cmus"; exit 0; }; ' +
            'command -v screen >/dev/null 2>&1 && { screen -dmS cmus sh -c "XDG_RUNTIME_DIR=' + Quickshell.env("XDG_RUNTIME_DIR") + ' HOME=' + Quickshell.env("HOME") + ' exec cmus"; exit 0; }; ' +
            'exit 1']
        onExited: _startRestartTimer.start()
    }

    // Small delay before re-querying: right after startup (inside tmux)
    // cmus has not yet finished initialising its library / control socket.
    // Rediscover its environment first — it's a fresh process, so this is
    // the first point we can actually read it back rather than assume it.
    // _envDiscoverProc.onExited chains into refresh() once that's done.
    Timer {
        id: _startRestartTimer
        interval: 1200
        onTriggered: root._discoverCmusEnv()
    }

    // ── Skip a whole album, forward or backward ─────────────
    // cmus has no native "next/previous album" command, so this steps
    // track by track via cmus-remote until the "tag album" changes,
    // relying on the library/queue being album-ordered — true when
    // browsing a directory tree of many albums, which is what this is
    // for. Each step is an async Process round-trip (query current album
    // -> step -> query again -> ...), chained through onExited /
    // onStreamFinished instead of the blocking loop cmus_skip_album() in
    // fabric-d77 uses (subprocess.run there is synchronous; Process here
    // is not).
    property string _albumSkipTarget:    ""
    property int    _albumSkipDirection: 1
    property int    _albumSkipStepsLeft: 0

    function skipAlbum(direction) {
        root._albumSkipDirection = direction
        root._albumSkipStepsLeft = 300
        _albumStartQuery.running = true
    }

    Process {
        id: _albumStartQuery
        running: false
        command: ["cmus-remote", "-Q"]
        environment: root.cmusEnv
        stdout: StdioCollector {
            onStreamFinished: {
                var q = root._parseQuery(text)
                if (q.status === "stopped") return
                // "" (untagged track) falls through to a single plain
                // track skip below, same fallback as the Python version.
                root._albumSkipTarget = q.album
                _albumStep.command = ["cmus-remote", root._albumSkipDirection > 0 ? "-n" : "-r"]
                _albumStep.running = true
            }
        }
    }

    Process {
        id: _albumStep
        running: false
        environment: root.cmusEnv
        onExited: _albumCheckQuery.running = true
    }

    Process {
        id: _albumCheckQuery
        running: false
        command: ["cmus-remote", "-Q"]
        environment: root.cmusEnv
        stdout: StdioCollector {
            onStreamFinished: {
                var q = root._parseQuery(text)
                if (q.status === "stopped" || root._albumSkipTarget === "" ||
                    q.album !== root._albumSkipTarget || root._albumSkipStepsLeft <= 0) {
                    root.refresh()
                    return
                }
                root._albumSkipStepsLeft--
                _albumStep.running = true
            }
        }
    }

    // ── Play a picked album ──────────────────────────────────
    // Uses the play queue (-q) rather than the playlist: -p alone just
    // resumes whatever cmus's current view (Library, by default) was
    // already on, ignoring playlist changes entirely — verified by hand
    // against a real library while porting this from fabric-d77's
    // cmus_play_album(). The play queue always takes priority over the
    // active view regardless of playback state, so this reliably jumps
    // straight to the picked album.
    property string _pendingAlbumPath:  ""
    property int    _albumPlayAttempts: 0

    function playAlbum(path) {
        root._pendingAlbumPath  = path
        root._albumPlayAttempts = 0
        _albumPlayProbe.running = true
    }

    // Probes whether cmus is reachable before queueing; starts it
    // headless and retries briefly (up to ~5s) if it isn't yet.
    Process {
        id: _albumPlayProbe
        running: false
        command: ["cmus-remote", "-Q"]
        environment: root.cmusEnv
        onExited: function (code) {
            if (code === 0) {
                root._queueAndPlay(root._pendingAlbumPath)
                return
            }
            if (root._albumPlayAttempts === 0)
                root.startHeadless()
            root._albumPlayAttempts++
            if (root._albumPlayAttempts < 20)
                _albumPlayRetryTimer.start()
        }
    }

    Timer {
        id: _albumPlayRetryTimer
        interval: 250
        onTriggered: _albumPlayProbe.running = true
    }

    function _queueAndPlay(path) {
        _qAddProc.command = ["cmus-remote", "-q", path]
        _qClearProc.running = true
    }

    Process { id: _qClearProc; running: false; command: ["cmus-remote", "-q", "-c"]; environment: root.cmusEnv; onExited: _qAddProc.running = true }
    Process { id: _qAddProc;   running: false; environment: root.cmusEnv; onExited: _qNextProc.running = true }
    Process { id: _qNextProc;  running: false; command: ["cmus-remote", "-n"]; environment: root.cmusEnv; onExited: _qPlayProc.running = true }
    Process { id: _qPlayProc;  running: false; command: ["cmus-remote", "-p"]; environment: root.cmusEnv; onExited: root.refresh() }
}
