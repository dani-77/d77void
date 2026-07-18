import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    property var appLauncher
    property var globalState
    property var lockScreen
    property var dashboard

    GlobalShortcut {
        appid: "quickshell"
        name: "launcher"
        description: "open/close app launcher"
        onPressed: appLauncher.toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "session"
        description: "open/close session menu (lock/suspend/reboot/...)"
        onPressed: globalState.sessionOpen = !globalState.sessionOpen
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "lock"
        description: "Lock the screen (native lockscreen)"
        onPressed: lockScreen.lock()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "dashboard"
        description: "open/close the quick info dashboard (stats, weather, cmus, session)"
        onPressed: dashboard.toggle()
    }
}
