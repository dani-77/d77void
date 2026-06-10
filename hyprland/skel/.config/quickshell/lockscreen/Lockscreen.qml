// ══════════════════════════════════════════════════════
// Lockscreen.qml
// Main component of the lockscreen module. Encapsulates the
// WlSessionLock + LockContext e expose a public API 
// (lock/unlock/toggle) ready to be IPC connected.
//
// Usage shell.qml:
//   import "lockscreen"
//   Lockscreen { id: lockScreen }
//   lockScreen.lock()    // block the screen
//   lockScreen.unlock()  // unblock (no password)
//
// Check README.md for details.
// ══════════════════════════════════════════════════════
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    // ══════════════════════════════════════════════════════
    // THEME (Tokyo Night)
    // ══════════════════════════════════════════════════════
    property color colBg:     "#1a1b26"
    property color colFg:     "#a9b1d6"
    property color colMuted:  "#444b6a"
    property color colBlue:   "#7aa2f7"
    property color colPurple: "#bb9af7"
    property color colRed:    "#f7768e"
    property string font:     "JetBrainsMono Nerd Font"
    property int    fsize:    13

    // ── State ────────────────────────────────────────────
    // true while screen is locked.
    readonly property alias locked: lock.locked

    // ── Signals ────────────────────────────────────────────
    // Emited when the lock state change.
    signal didLock()
    signal didUnlock()

    // ══════════════════════════════════════════════════════
    // Public API (via IPC)
    // ══════════════════════════════════════════════════════
    // Lock the screen. Session locked until the password
    // is validated via PAM (or unlock() if called).
    function lock() {
        if (lock.locked) return
        lockContext.currentText      = ""
        lockContext.showFailure      = false
        lockContext.unlockInProgress = false
        lock.locked = true
        root.didLock()
    }

    // Unlock the screen, without password.
    function unlock() {
        if (!lock.locked) return
        lock.locked = false
        lockContext.currentText      = ""
        lockContext.showFailure      = false
        lockContext.unlockInProgress = false
        root.didUnlock()
    }

    // Alternates between locked/unlocked.
    function toggle() {
        if (lock.locked) unlock()
        else             lock()
    }

    // ══════════════════════════════════════════════════════
    // SHARED CONTEXT + AUTHENTICATION
    // ══════════════════════════════════════════════════════
    LockContext {
        id: lockContext

        onUnlocked: {
            lock.locked = false
            root.didUnlock()
        }
    }

    // ══════════════════════════════════════════════════════
    // LOCKED SESSION
    // ══════════════════════════════════════════════════════
    WlSessionLock {
        id: lock
        locked: false

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: lockContext

                // THEME
                colBg:     root.colBg
                colFg:     root.colFg
                colMuted:  root.colMuted
                colBlue:   root.colBlue
                colPurple: root.colPurple
                colRed:    root.colRed
                font:      root.font
                fsize:     root.fsize
            }
        }
    }
}
