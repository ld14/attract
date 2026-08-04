// El panel de caratula del detalle: video de gameplay en loop cuando lo hay,
// con los controles de transporte que dibuja el theme.
//
// SIN VIDEO NO QUEDA UN HUECO: se muestra la caratula, con su cadena de
// fallback de CONVENCION #2.2 (nota 2 de #2.1). El prototipo ponia un
// color-wash; acá la caratula es mejor dato y ya la tenemos.
//
// TRES COSAS QUE NO SON NEGOCIABLES, y las tres salen de medir, no de suponer:
//
//   1. Los controles se revelan por FOCO, no por hover. El gabinete no tiene
//      mouse. El handoff lo pide explicitamente.
//   2. `source: ""` al desactivarse. Sin eso el gabinete acumula decoders al
//      entrar y salir de fichas.
//   3. NADA colgado de `onStopped`: no se dispara en un loop continuo
//      (docs/plataforma-pegasus.md #2, medido). Si algun dia hace falta saber
//      que el video reengancho, la senal es que la posicion retroceda.
//
// Y una decision de producto: arranca en MUTE. Un gabinete que se pone a
// sonar solo al mover el foco por el rail es insoportable.

import QtQuick 2.0
import QtMultimedia 5.9
import ".."
import "../ui"

Item {
    id: root

    property var game: null
    property color accent: Theme.accentNeutro
    property color accent2: Theme.accent2Neutro

    // Lo maneja la pantalla: este panel esta enfocado dentro del detalle.
    property bool activo: false

    // Se apaga al salir del detalle. Es lo que libera el decoder.
    property bool encendido: true

    readonly property bool hayVideo:
        game !== null && game.assets && game.assets.video ? true : false

    // --- el fondo: caratula siempre, video encima cuando lo hay -----------

    CoverImage {
        anchors.fill: parent
        game: root.game
        accent: root.accent
        accent2: root.accent2
    }

    MediaPlayer {
        id: player
        // Regla 2: al apagarse suelta el archivo. No alcanza con pausar.
        source: (root.encendido && root.hayVideo) ? root.game.assets.video : ""
        autoPlay: true
        loops: MediaPlayer.Infinite
        volume: 0.6
        muted: true                 // arranca en silencio, a proposito
    }

    VideoOutput {
        anchors.fill: parent
        source: player
        fillMode: VideoOutput.PreserveAspectCrop
        visible: root.hayVideo && root.encendido
    }

    // Vineta: el titulo de abajo tiene que leerse sobre cualquier fotograma.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.alpha(Theme.screen, 0.35) }
            GradientStop { position: 0.45; color: "transparent" }
            GradientStop { position: 1.0; color: Theme.alpha(Theme.screen, 0.92) }
        }
    }

    // --- pill "GAMEPLAY" con el punto que late ----------------------------

    Rectangle {
        anchors { top: parent.top; right: parent.right; margins: 12 }
        visible: root.hayVideo && root.encendido
        width: fila.width + 18
        height: 22
        radius: 11
        color: Theme.alpha(Theme.screen, 0.72)
        border.width: 1
        border.color: Theme.glassBorder

        Row {
            id: fila
            anchors.centerIn: parent
            spacing: 7

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 7; height: 7; radius: 3.5
                color: "#ff4444"
                // El latido de 1.6s del diseno.
                SequentialAnimation on opacity {
                    running: root.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 800 }
                    NumberAnimation { to: 1.0; duration: 800 }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "GAMEPLAY"
                color: Theme.textPrimary
                font.family: Theme.fontMono
                font.pixelSize: 9
                font.letterSpacing: 0.1 * 9
            }
        }
    }

    // --- el titulo del juego, al pie --------------------------------------

    Text {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        anchors.margins: 16
        anchors.bottomMargin: root.activo && root.hayVideo ? 54 : 16
        height: 108
        wrapMode: Text.WordWrap
        maximumLineCount: 4
        color: Theme.textBright
        font.family: Theme.fontDisplay
        font.bold: true
        lineHeight: 1.0
        verticalAlignment: Text.AlignBottom
        fontSizeMode: Text.Fit
        font.pixelSize: Theme.sizePanelTitle
        minimumPixelSize: 14
        text: root.game ? root.game.title.toUpperCase() : ""

        Behavior on anchors.bottomMargin { NumberAnimation { duration: 200 } }
    }

    // --- transporte -------------------------------------------------------
    //
    // Regla 1: aparece con el FOCO. El `translateY` de 8px del diseno se
    // conserva; el hover no, porque no existe en el gabinete.

    Item {
        id: transporte
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 46
        visible: opacity > 0
        opacity: (root.activo && root.hayVideo && root.encendido) ? 1 : 0
        transform: Translate { y: transporte.opacity > 0 ? 0 : 8 }

        Behavior on opacity { NumberAnimation { duration: 200 } }

        // Cual de los cuatro controles esta elegido. Arriba/abajo lo mueven
        // MIENTRAS este panel tiene el foco; izquierda/derecha siguen
        // recorriendo los targets del detalle. Esa es la regla general del
        // detalle: horizontal mueve ENTRE targets, vertical actua DENTRO del
        // target enfocado. Ya la usaba el carrusel; acá se generaliza.
        property int control: 0
        readonly property int controles: 4

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.12; color: Theme.alpha("#05070b", 0.94) }
                GradientStop { position: 1.0; color: Theme.alpha("#05070b", 0.94) }
            }
        }

        Row {
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 8

            // 0 · play / pausa
            Boton {
                texto: ""
                glifo: player.playbackState === MediaPlayer.PlayingState ? "❚❚" : "▶"
                variant: "glass"
                accent: root.accent
                activo: transporte.control === 0
                implicitWidth: 30
                implicitHeight: 30
                onActivado: root.alternarPlay()
            }

            // 1 · volumen abajo
            Boton {
                texto: ""
                glifo: "−"
                variant: "glass"
                accent: root.accent
                activo: transporte.control === 1
                implicitWidth: 30
                implicitHeight: 30
                onActivado: root.subirVolumen(-0.2)
            }

            // 2 · volumen arriba
            Boton {
                texto: ""
                glifo: "+"
                variant: "glass"
                accent: root.accent
                activo: transporte.control === 2
                implicitWidth: 30
                implicitHeight: 30
                onActivado: root.subirVolumen(0.2)
            }

            MedidorVolumen {
                anchors.verticalCenter: parent.verticalCenter
                volumen: player.volume
                muteado: player.muted
                accent: root.accent
            }
        }

        // 3 · mute, a la derecha del todo
        Boton {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            texto: ""
            // El diseno tacha un altavoz; el glifo unicode ya trae la version
            // tachada, que se lee igual y no obliga a dibujarla a mano.
            glifo: player.muted ? "🔇" : "🔊"
            variant: "glass"
            accent: player.muted ? "#ff5a5a" : root.accent
            activo: transporte.control === 3
            implicitWidth: 32
            implicitHeight: 30
            onActivado: root.alternarMute()
        }
    }

    // --- acciones ---------------------------------------------------------

    function alternarPlay() {
        if (player.playbackState === MediaPlayer.PlayingState) player.pause();
        else player.play();
    }

    function subirVolumen(delta) {
        var v = Math.max(0, Math.min(1, Math.round((player.volume + delta) * 100) / 100));
        player.volume = v;
        // Subir el volumen desmutea: es lo que espera cualquiera que aprieta
        // "+" estando en silencio.
        if (v > 0 && delta > 0) player.muted = false;
    }

    function alternarMute() {
        player.muted = !player.muted;
        // Desmutear con el volumen en cero no haria nada audible.
        if (!player.muted && player.volume <= 0) player.volume = 0.5;
    }

    // Devuelve true si consumio la tecla. Lo llama la pantalla mientras este
    // panel tiene el foco.
    function manejarTecla(event) {
        if (!activo || !hayVideo) return false;

        if (event.key === Qt.Key_Down) {
            transporte.control = (transporte.control + 1) % transporte.controles;
            return true;
        }
        if (event.key === Qt.Key_Up) {
            transporte.control = (transporte.control - 1 + transporte.controles)
                                 % transporte.controles;
            return true;
        }
        if (api.keys.isAccept(event)) {
            if (transporte.control === 0) alternarPlay();
            else if (transporte.control === 1) subirVolumen(-0.2);
            else if (transporte.control === 2) subirVolumen(0.2);
            else alternarMute();
            return true;
        }
        return false;
    }
}
