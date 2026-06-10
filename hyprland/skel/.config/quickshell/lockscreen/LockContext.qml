// ══════════════════════════════════════════════════════
// LockContext.qml
// Shared state + PAM authentication on the lockscreen.
// Based on the official quickshell-examples example, adapted
// to quickshell-d77 (README.md).
//
// Keep the state in one place so that all the "lock
// surfaces" (one per monitor) share the same text/state.
// ══════════════════════════════════════════════════════
import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root

    // Issued when PAM authentication is successful.
    signal unlocked()
    // Issued when PAM authentication is unsuccessful.
    signal failed()

    // ── Shared state between surfaces ───────────────
    property string currentText: ""
    property bool   unlockInProgress: false
    property bool   showFailure: false

    // Clears the error message as soon as the user types again.
    onCurrentTextChanged: showFailure = false

    // ── Try unlocking by validating the password via PAM ────
    function tryUnlock() {
        if (currentText === "") return
        root.unlockInProgress = true
        pam.start()
    }

    PamContext {
        id: pam

        configDirectory: "pam"
        config: "password.conf"


        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.currentText)
            }
        }


        onCompleted: result => {
            if (result == PamResult.Success) {
                root.unlocked()
            } else {
                root.currentText = ""
                root.showFailure = true
                root.failed()
            }
            root.unlockInProgress = false
        }
    }
}
