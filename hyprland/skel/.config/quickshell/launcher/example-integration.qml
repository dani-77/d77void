// ══════════════════════════════════════════════════════
// example-integration.qml
// Exemplo MÍNIMO de como ativar o módulo launcher a partir
// da configuração principal do Quickshell (shell.qml).
//
// Este arquivo é apenas demonstrativo — copie os trechos
// marcados para dentro do seu shell.qml.
//
// Para testar isoladamente:
//   qs -p ~/.config/quickshell/launcher/example-integration.qml
// ══════════════════════════════════════════════════════
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// (1) Importe o módulo launcher pelo caminho relativo.
//     A pasta "launcher" precisa estar ao lado do shell.qml.
import "launcher"

ShellRoot {

    // (2) Instancie o Launcher uma única vez. Ele começa
    //     invisível e é mostrado via launcher.toggle().
    Launcher {
        id: appLauncher
        // O tema já usa a paleta Tokyo Night por padrão,
        // mas você pode sobrescrever qualquer propriedade:
        // colPurple: "#bb9af7"
        // terminal:  "foot"
    }

    // (3) Atalho global via Hyprland para abrir/fechar.
    //     Equivale a "bind = SUPER, D, ..." mas tratado aqui.
    GlobalShortcut {
        name: "launcher"
        description: "Abre o launcher de aplicativos"
        onPressed: appLauncher.toggle()
    }

    // (4) Botão na barra que abre o launcher nativo no lugar
    //     de chamar o "fuzzel" via Process.
    PanelWindow {
        anchors.top:  true
        anchors.left: true
        implicitHeight: 40
        implicitWidth:  60
        color: "#1a1b26"

        Rectangle {
            anchors.centerIn: parent
            width: 26; height: 26; radius: 6
            color: ma.containsMouse ? "#c7b3f9" : "#bb9af7"

            Text {
                anchors.centerIn: parent
                text: ""
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                color: "#1a1b26"
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                // ── ANTES (chamava o fuzzel) ──────────────
                // onClicked: {
                //     launcherProc.command = ["fuzzel"]
                //     launcherProc.running = true
                // }
                // ── DEPOIS (usa o módulo nativo) ──────────
                onClicked: appLauncher.toggle()
            }
        }
    }
}
