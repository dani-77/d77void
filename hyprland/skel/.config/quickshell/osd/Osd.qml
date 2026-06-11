// ══════════════════════════════════════════════════════
// Osd.qml — On-Screen Display (volume + brilho)
// ──────────────────────────────────────────────────────
// Overlay minimalista (ícone + barra de progresso) que
// aparece no canto superior direito quando o volume ou o
// brilho mudam, e desaparece após ~2,5 s.
//
// Backends:
//   • Volume  → ALSA (amixer), com suporte a mute/unmute
//   • Brilho  → brightnessctl
//
// Adaptado do exemplo "volume-osd" do quickshell-examples
// (https://github.com/quickshell-mirror/quickshell-examples),
// reescrito para ALSA + brightnessctl e integrado no
// quickshell-d77 com a paleta Tokyo Night.
//
// API pública (normalmente acionada por IPC / keybinds):
//   volumeUp()        — sobe o volume (passo `step`)
//   volumeDown()      — desce o volume (passo `step`)
//   volumeMuteToggle()— alterna mute/unmute
//   brightnessUp()    — aumenta o brilho (passo `step`)
//   brightnessDown()  — diminui o brilho (passo `step`)
//   showVolume()      — apenas lê e mostra o OSD de volume
//   showBrightness()  — apenas lê e mostra o OSD de brilho
// ══════════════════════════════════════════════════════
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Scope {
    id: root

    // ── Tema (Tokyo Night por defeito; pode ser sobreposto) ──
    property color colBg:     "#1a1b26"
    property color colFg:     "#a9b1d6"
    property color colMuted:  "#444b6a"
    property color colBlue:   "#7aa2f7"
    property color colPurple: "#bb9af7"
    property color colRed:    "#f7768e"
    property color colYellow: "#e0af68"
    property string font:     "JetBrainsMono Nerd Font"
    property int    fsize:    13

    // ── Configuração ────────────────────────────────────
    // Passo (em %) para subir/descer volume e brilho.
    property int    step:        5
    // Tempo (ms) que o OSD fica visível após a última mudança.
    property int    timeout:     2500
    // Nome do controlo ALSA (normalmente "Master").
    property string mixerControl: "Master"

    // ── Estado interno ──────────────────────────────────
    property int    volLevel:  0      // 0..100
    property bool   volMuted:  false
    property int    briLevel:  0      // 0..100
    // Modo atual do overlay: "volume" ou "brightness".
    property string mode:      "volume"
    property bool   shouldShow: false

    // ──────────────────────────────────────────────────
    // API PÚBLICA
    // ──────────────────────────────────────────────────
    function volumeUp() {
        volSetProc.command = ["sh", "-c",
            "amixer set " + root.mixerControl + " " + root.step + "%+ >/dev/null 2>&1; " + root._volReadCmd()]
        volSetProc.running = true
    }
    function volumeDown() {
        volSetProc.command = ["sh", "-c",
            "amixer set " + root.mixerControl + " " + root.step + "%- >/dev/null 2>&1; " + root._volReadCmd()]
        volSetProc.running = true
    }
    function volumeMuteToggle() {
        volSetProc.command = ["sh", "-c",
            "amixer set " + root.mixerControl + " toggle >/dev/null 2>&1; " + root._volReadCmd()]
        volSetProc.running = true
    }
    function showVolume() {
        volSetProc.command = ["sh", "-c", root._volReadCmd()]
        volSetProc.running = true
    }
    function brightnessUp() {
        briSetProc.command = ["sh", "-c",
            "brightnessctl set " + root.step + "%+ >/dev/null 2>&1; " + root._briReadCmd()]
        briSetProc.running = true
    }
    function brightnessDown() {
        briSetProc.command = ["sh", "-c",
            "brightnessctl set " + root.step + "%- >/dev/null 2>&1; " + root._briReadCmd()]
        briSetProc.running = true
    }
    function showBrightness() {
        briSetProc.command = ["sh", "-c", root._briReadCmd()]
        briSetProc.running = true
    }

    // ── Helpers (comandos de leitura) ───────────────────
    // Devolve "<nivel> <muted>" — ex.: "45 0".
    function _volReadCmd() {
        return "v=$(amixer get " + root.mixerControl +
               " | grep -Po '\\[\\d+%\\]' | head -1 | tr -d '[]%'); " +
               "m=$(amixer get " + root.mixerControl +
               " | grep -q '\\[off\\]' && echo 1 || echo 0); echo \"$v $m\""
    }
    // Devolve o brilho em % (campo 4 de `brightnessctl -m`).
    function _briReadCmd() {
        return "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'"
    }

    function _reveal() {
        root.shouldShow = true
        hideTimer.restart()
    }

    // ──────────────────────────────────────────────────
    // PROCESSOS
    // ──────────────────────────────────────────────────
    // Aplica a mudança de volume e lê o novo estado.
    Process {
        id: volSetProc
        running: false
        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "") return
                var parts = data.trim().split(/\s+/)
                if (parts[0] !== undefined && parts[0] !== "")
                    root.volLevel = parseInt(parts[0])
                if (parts[1] !== undefined)
                    root.volMuted = (parts[1] === "1")
                root.mode = "volume"
                root._reveal()
            }
        }
    }

    // Aplica a mudança de brilho e lê o novo estado.
    Process {
        id: briSetProc
        running: false
        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "") return
                root.briLevel = parseInt(data.trim())
                root.mode = "brightness"
                root._reveal()
            }
        }
    }

    // ── Watcher: deteta mudanças externas (opcional) ────
    // Lê volume e brilho periodicamente; se mudarem sem ter
    // sido nós a provocá-lo (ex.: teclas multimédia tratadas
    // por outro programa), mostra o OSD à mesma.
    property bool   _initVol: false
    property bool   _initBri: false
    property int    _lastVol: -1
    property bool   _lastMuted: false
    property int    _lastBri: -1

    Process {
        id: volWatchProc
        running: false
        command: ["sh", "-c", root._volReadCmd()]
        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "") return
                var parts = data.trim().split(/\s+/)
                var lvl = parseInt(parts[0])
                var mut = (parts[1] === "1")
                if (isNaN(lvl)) return
                if (root._initVol && (lvl !== root._lastVol || mut !== root._lastMuted)) {
                    root.volLevel = lvl
                    root.volMuted = mut
                    root.mode = "volume"
                    root._reveal()
                }
                root._lastVol = lvl
                root._lastMuted = mut
                root._initVol = true
                // Mantém o estado base sincronizado mesmo sem OSD.
                if (!root.shouldShow || root.mode === "volume") {
                    root.volLevel = lvl
                    root.volMuted = mut
                }
            }
        }
    }

    Process {
        id: briWatchProc
        running: false
        command: ["sh", "-c", root._briReadCmd()]
        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "") return
                var lvl = parseInt(data.trim())
                if (isNaN(lvl)) return
                if (root._initBri && lvl !== root._lastBri) {
                    root.briLevel = lvl
                    root.mode = "brightness"
                    root._reveal()
                }
                root._lastBri = lvl
                root._initBri = true
                if (!root.shouldShow || root.mode === "brightness") {
                    root.briLevel = lvl
                }
            }
        }
    }

    Timer {
        id: watchTimer
        interval: 700
        running: true
        repeat: true
        onTriggered: {
            volWatchProc.running = true
            briWatchProc.running = true
        }
    }

    // Esconde o OSD após `timeout` ms sem mudanças.
    Timer {
        id: hideTimer
        interval: root.timeout
        onTriggered: root.shouldShow = false
    }

    // ──────────────────────────────────────────────────
    // OVERLAY (canto superior direito)
    // ──────────────────────────────────────────────────
    // Usa LazyLoader para não ocupar memória quando escondido.
    LazyLoader {
        active: root.shouldShow

        PanelWindow {
            // Sem `screen` definido → o compositor escolhe o
            // monitor ativo no momento da criação.
            anchors.top:   true
            anchors.right: true
            margins.top:   16
            margins.right: 16
            exclusiveZone: 0

            implicitWidth:  300
            implicitHeight: 56
            color: "transparent"

            // Máscara vazia → não bloqueia eventos do rato.
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: Qt.rgba(0.10, 0.11, 0.15, 0.92)   // colBg translúcido
                border.color: Qt.rgba(0.27, 0.29, 0.42, 0.6)
                border.width: 1

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 18
                    }
                    spacing: 14

                    // ── Ícone (Nerd Font) ──────────────────
                    Text {
                        id: osdIcon
                        Layout.alignment: Qt.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        Layout.preferredWidth: 26
                        font.family: root.font
                        font.pixelSize: 22
                        color: {
                            if (root.mode === "brightness") return root.colYellow
                            return root.volMuted ? root.colRed : root.colPurple
                        }
                        text: {
                            if (root.mode === "brightness") {
                                return root.briLevel > 66 ? "󰃠" : root.briLevel > 33 ? "󰃟" : "󰃞"
                            }
                            if (root.volMuted) return "󰝟"
                            return root.volLevel > 50 ? "󰕾" : root.volLevel > 0 ? "󰖀" : "󰕿"
                        }
                    }

                    // ── Barra de progresso ─────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 8
                        radius: height / 2
                        color: Qt.rgba(1, 1, 1, 0.16)

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            radius: parent.radius
                            width: parent.width * (
                                root.mode === "brightness"
                                    ? Math.max(0, Math.min(1, root.briLevel / 100))
                                    : (root.volMuted ? 0 : Math.max(0, Math.min(1, root.volLevel / 100)))
                            )
                            color: {
                                if (root.mode === "brightness") return root.colYellow
                                return root.volMuted ? root.colMuted : root.colPurple
                            }
                            Behavior on width {
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    // ── Valor numérico ─────────────────────
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 38
                        horizontalAlignment: Text.AlignRight
                        font.family: root.font
                        font.pixelSize: root.fsize
                        font.bold: true
                        color: root.colFg
                        text: root.mode === "brightness"
                            ? root.briLevel + "%"
                            : (root.volMuted ? "mute" : root.volLevel + "%")
                    }
                }
            }
        }
    }
}
