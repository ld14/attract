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
//
// TRES MODOS, no uno (ADR-0021). El overlay nacio para "estamos lanzando algo
// afuera", y abrir el PDF del manual es el mismo problema con otra cara, asi
// que se generalizo en vez de escribir un componente gemelo:
//
//   "lanzando"    spinner + Timer que cierra solo. El original.
//   "confirmar"   sin spinner, sin Timer: espera A. Se usa antes de abrir el
//                 PDF, porque en el gabinete abrirlo es un viaje de ida (el
//                 foco se va y con joystick no vuelve).
//   "error"       sin spinner, sin Timer: solo se cierra con B.
//
// Los dos modos nuevos NO tienen Timer a proposito. El auto-cierre del original
// existe porque el lanzamiento no avisa si fallo; una pregunta que se contesta
// sola no seria una pregunta, y un error que se borra solo no se lee.

import QtQuick 2.0
import ".."

FocusScope {
    id: root

    property var game: null
    property color accent: Theme.accentNeutro

    // "lanzando" | "confirmar" | "error"
    property string modo: "lanzando"

    // Los tres renglones. Vacios, cada uno cae a lo que mostraba el original,
    // asi que el lanzamiento de un juego sigue funcionando sin pasarle nada.
    property string titulo: ""
    property string encabezado: ""
    property string detalle: ""

    // Un cuarto renglon opcional, para explicar que hacer. Solo lo usa "error".
    property string nota: ""

    // Margen para que Pegasus tome la pantalla. Si seguimos vivos despues de
    // esto, el lanzamiento fallo.
    property int msSalida: 6000

    signal cerrar()
    signal aceptar()

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
        //
        // Solo en "lanzando": en los otros dos no estamos esperando nada, y un
        // spinner que gira sobre una pregunta o un error miente.
        Item {
            width: 46; height: 46
            visible: root.modo === "lanzando"
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
            width: 760
            horizontalAlignment: Text.AlignHCenter
            text: root.titulo !== "" ? root.titulo : "INICIANDO"
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
            text: {
                if (root.encabezado !== "") return root.encabezado;
                return root.game ? root.game.title.toUpperCase() : "";
            }
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
                if (root.detalle !== "") return root.detalle;
                if (!root.game || root.game.files === undefined) return "";
                if (root.game.files.count < 1) return "";
                return String(root.game.files.get(0).path);
            }
        }

        // Que hacer al respecto. Solo aparece si alguien tiene algo que decir:
        // un renglon vacio ocupando lugar es peor que no estar.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 700
            visible: root.nota !== ""
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: Theme.sizeLabel
            text: root.nota
        }
    }

    Text {
        anchors { bottom: parent.bottom; bottomMargin: 58 }
        anchors.horizontalCenter: parent.horizontalCenter
        color: Theme.textFaint
        font.family: Theme.fontMono
        font.pixelSize: Theme.sizeMonoSm
        font.letterSpacing: Theme.trackingLabel * Theme.sizeMonoSm
        // Nombrar UNA tecla es mentira la mitad del tiempo: este Pegasus
        // mapea `keys.cancel: Esc,Backspace,GamepadB` — la B es la del
        // gamepad, en teclado no existe. El gabinete va a tener joystick
        // y el Mac de desarrollo no, asi que se nombran las dos.
        // (El diseno asumia joystick y decia solo "B".)
        text: root.modo === "confirmar"
              ? "— A · ENTER ABRIR    B · ESC VOLVER —"
              : "— B · ESC PARA VOLVER —"
    }

    // Solo en "lanzando". Una pregunta que se contesta sola no es una pregunta,
    // y un error que se borra solo no se llega a leer.
    Timer {
        interval: root.msSalida
        running: root.visible && root.modo === "lanzando"
        onTriggered: root.cerrar()
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            root.cerrar();
            event.accepted = true;
        } else if (root.modo === "confirmar" && api.keys.isAccept(event)) {
            root.aceptar();
            event.accepted = true;
        }
    }
}
