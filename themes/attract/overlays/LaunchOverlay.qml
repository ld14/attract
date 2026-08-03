// El overlay de "INICIANDO": scrim, spinner y el titulo del juego, mientras
// Pegasus arranca el emulador.
//
// DOS COSAS QUE EL HANDOFF DABA POR SENTADAS Y LA API DE PEGASUS NO DA
// (verificado en pegasus-frontend.org/docs/themes/api el 2026-08-03):
//
//   1. "el comando de lanzamiento real resuelto por Pegasus" NO se puede
//      mostrar: no esta expuesto. La API tiene game.launch() y nada mas. En
//      su lugar se muestra la ruta del archivo (files[0].path), que si
//      tenemos y es dato real, no una simulacion como la del prototipo.
//
//   2. NO hay ninguna senal de que el lanzamiento haya salido bien o mal. La
//      documentacion dice que un fallo "se loguea" y punto. Eso significa que
//      un overlay que espere "hasta que arranque el juego" se queda colgado
//      PARA SIEMPRE cuando el lanzamiento falla — y falla de verdad: ya se
//      vio "Could not launch `mame`" en este mismo Mac, porque una app de GUI
//      en macOS no hereda el PATH del shell y mame vive en /usr/local/bin.
//
// Por eso el overlay se cierra solo. No es paranoia defensiva: es el unico
// camino de salida que existe. Cuando el lanzamiento SI funciona, Pegasus
// suspende el theme y el timer no llega a correr; si el theme sigue vivo
// pasados unos segundos, es que el juego nunca arranco.
//
// El boton de cancelar tambien lo cierra, para no tener que esperar.

import QtQuick 2.0
import ".."

FocusScope {
    id: root

    property var game: null
    property color accent: Theme.accentNeutro

    // Margen para que Pegasus tome la pantalla. Si seguimos vivos despues de
    // esto, el lanzamiento fallo.
    property int msSalida: 6000

    signal cerrar()

    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.screen, 0.88)
    }

    Column {
        anchors.centerIn: parent
        spacing: 22

        // spinner: un arco que gira. Canvas y no QtGraphicalEffects, que
        // sigue sin verificarse contra este binario.
        Item {
            width: 46; height: 46
            anchors.horizontalCenter: parent.horizontalCenter

            Canvas {
                id: arco
                anchors.fill: parent
                renderStrategy: Canvas.Cooperative

                property color c: root.accent
                onCChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var r = width / 2 - 3;
                    ctx.lineWidth = 3;
                    ctx.strokeStyle = Theme.alpha(c, 0.18);
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, r, 0, Math.PI * 2);
                    ctx.stroke();

                    ctx.strokeStyle = c;
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, r, 0, Math.PI * 0.6);
                    ctx.stroke();
                }

                RotationAnimation on rotation {
                    from: 0; to: 360
                    duration: 800          // los 0.8s lineales del diseno
                    loops: Animation.Infinite
                    running: root.visible
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "INICIANDO"
            color: root.accent
            font.family: Theme.fontMono
            font.pixelSize: Theme.sizeMono
            font.letterSpacing: 0.2 * Theme.sizeMono
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 700
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            color: Theme.textBright
            font.family: Theme.fontDisplay
            font.bold: true
            fontSizeMode: Text.HorizontalFit
            font.pixelSize: 32
            minimumPixelSize: 18
            text: root.game ? root.game.title.toUpperCase() : ""
        }

        // La ruta real del archivo. El prototipo simulaba un
        // "launch: retroarch -L core.dll ..." inventado; esto es el dato que
        // la API si da.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 700
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
            color: Theme.textFaint
            font.family: Theme.fontMono
            font.pixelSize: Theme.sizeMonoSm
            text: {
                if (!root.game || root.game.files === undefined) return "";
                if (root.game.files.count < 1) return "";
                return String(root.game.files.get(0).path);
            }
        }
    }

    Text {
        anchors { bottom: parent.bottom; bottomMargin: 58 }
        anchors.horizontalCenter: parent.horizontalCenter
        color: Theme.textFaint
        font.family: Theme.fontMono
        font.pixelSize: Theme.sizeMonoSm
        font.letterSpacing: Theme.trackingLabel * Theme.sizeMonoSm
        text: "— B PARA VOLVER —"
    }

    Timer {
        interval: root.msSalida
        running: root.visible
        onTriggered: root.cerrar()
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            root.cerrar();
            event.accepted = true;
        }
    }
}
