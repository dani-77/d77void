// ══════════════════════════════════════════════════════
// greeter/shell.qml
// Standalone entry point for the native quickshell-d77 greeter.
// greetd starts *this* file directly (via a Wayland compositor host,
// see assets/greet-hyprland.sh) instead of the main shell.qml, since
// the greeter runs before any user session exists.
//
// Run manually for testing with:
//   qs -p ~/Projectos/quickshell-d77/greeter
// (needs a Wayland compositor with zwlr_layer_shell_v1, e.g. Hyprland,
// and a running greetd — see README.md).
// ══════════════════════════════════════════════════════
import Quickshell

ShellRoot {
    Greeter {
        id: greeter
    }
}
