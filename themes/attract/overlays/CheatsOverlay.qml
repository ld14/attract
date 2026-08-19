// El overlay TRUCOS & COMBOS: un tablero de comandos de arcade, no una lista.
//
// Lo que lo hace distinto de una tabla de texto es que las secuencias se
// DIBUJAN como botones (ui/InputTokenRow.qml + core/InputTokens.js). Alguien
// parado frente a un gabinete no lee "↓ ↙ ← ↓ ↙ ← + PP", pero reconoce media
// luna, media luna, dos puños.
//
// LAS SECCIONES VACIAS SE OCULTAN, y CONVENCION #2.3 no aplica acá. Esa regla
// -"ningun bloque desaparece"- existe para que la estructura de una PANTALLA
// sea estable y el ojo encuentre las cosas siempre en el mismo lugar. Esto es
// un overlay que se abre a pedido y solo cuando hay contenido: mostrar
// "CODIGOS SECRETOS · 00 SECRETOS · No Disponible" no le informa nada a quien
// acaba de pedir ver los trucos. La tarjeta Hacks del detalle, que SI es parte
// de una pantalla, se sigue mostrando siempre con su mensaje.

import QtQuick 2.0
import QtGraphicalEffects 1.0
import ".."
import "../ui"
import "../core/InputTokens.js" as Tokens

FocusScope {
    id: root

    property var datos: null            // el GameData del juego
    property string titulo: ""
    property color accent: Theme.accentNeutro
    property Item fondo: null

    signal cerrar()

    anchors.fill: parent

    // Ya normalizados por GameData: [{ clave, label, items }]. Este overlay
    // no vuelve a preguntar si el grupo vino como lista o como objeto con
    // label — esa decision se toma en un solo lugar (ADR-0020).
    readonly property var grupos: datos ? datos.gruposCheats : []

    // --- fondo ------------------------------------------------------------

    FastBlur {
        anchors.fill: parent
        source: root.fondo
        radius: 40
        visible: root.fondo !== null
        cached: true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(5/255, 6/255, 9/255, 0.86)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.cerrar()
    }

    // --- el panel ---------------------------------------------------------

    Item {
        id: panel
        width: Math.min(900, parent.width - 2 * Theme.gutter)
        height: Math.min(parent.height * 0.88, contenido.height + 96)
        anchors.centerIn: parent

        Rectangle {
            id: caja
            anchors.fill: parent
            radius: 4
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#0e1119" }
                GradientStop { position: 1.0; color: "#07080c" }
            }
            border.width: 1
            border.color: Theme.alpha(root.accent, 0.45)
        }

        // Scanlines: la textura de tablero iluminado del diseno.
        Canvas {
            anchors.fill: parent
            opacity: 0.07
            renderStrategy: Canvas.Cooperative
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = Qt.rgba(1, 1, 1, 0.6);
                for (var y = 0; y < height; y += 3) ctx.fillRect(0, y, width, 1);
            }
        }

        // Las cuatro escuadras HUD. Mismo patron que ReviewCard, ya probado.
        Repeater {
            model: [[0, 0], [1, 0], [0, 1], [1, 1]]
            Item {
                width: 16; height: 16
                x: modelData[0] === 0 ? -1 : panel.width - 15
                y: modelData[1] === 0 ? -1 : panel.height - 15
                Rectangle {
                    width: 16; height: 2
                    anchors.top: modelData[1] === 0 ? parent.top : undefined
                    anchors.bottom: modelData[1] === 1 ? parent.bottom : undefined
                    anchors.left: modelData[0] === 0 ? parent.left : undefined
                    anchors.right: modelData[0] === 1 ? parent.right : undefined
                    color: root.accent
                }
                Rectangle {
                    width: 2; height: 16
                    anchors.top: modelData[1] === 0 ? parent.top : undefined
                    anchors.bottom: modelData[1] === 1 ? parent.bottom : undefined
                    anchors.left: modelData[0] === 0 ? parent.left : undefined
                    anchors.right: modelData[0] === 1 ? parent.right : undefined
                    color: root.accent
                }
            }
        }

        // --- cabecera -----------------------------------------------------

        Item {
            id: cabecera
            anchors { top: parent.top; left: parent.left; right: parent.right }
            anchors.margins: 18
            height: 46

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40; height: 40
                    radius: 8
                    color: Theme.alpha(root.accent, 0.14)
                    border.width: 1
                    border.color: Theme.alpha(root.accent, 0.45)
                    Text {
                        anchors.centerIn: parent
                        text: "☠"
                        color: root.accent
                        font.pixelSize: 20
                    }
                }

                // El diamante que parpadea, del diseno.
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8; height: 8
                    rotation: 45
                    color: root.accent
                    SequentialAnimation on opacity {
                        running: root.visible
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.2; duration: 700 }
                        NumberAnimation { to: 1.0; duration: 700 }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Text {
                        text: "TRUCOS & COMBOS"
                        color: Theme.textBright
                        font.family: Theme.fontDisplay
                        font.bold: true
                        font.pixelSize: 20
                        font.letterSpacing: 0.05 * 20
                    }
                    Text {
                        text: root.titulo + "  ·  LISTA DE COMANDOS"
                        color: Theme.textFaint
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.letterSpacing: 0.08 * 10
                    }
                }
            }

            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 12

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30; height: 22
                    radius: 5
                    color: Theme.alpha(root.accent, 0.16)
                    border.width: 1
                    border.color: Theme.alpha(root.accent, 0.5)
                    Text {
                        anchors.centerIn: parent
                        text: "P1"
                        color: root.accent
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                Boton {
                    texto: ""; glifo: "✕"; variant: "glass"; accent: root.accent
                    implicitWidth: 32; implicitHeight: 30
                    onActivado: root.cerrar()
                }
            }
        }

        Rectangle {
            id: reglaCabecera
            anchors { top: cabecera.bottom; topMargin: 12 }
            anchors { left: parent.left; right: parent.right; leftMargin: 18; rightMargin: 18 }
            height: 1
            color: Theme.alpha(root.accent, 0.22)
        }

        // --- cuerpo -------------------------------------------------------

        Flickable {
            id: scroll
            anchors { top: reglaCabecera.bottom; topMargin: 16 }
            anchors { left: parent.left; right: parent.right; bottom: pie.top }
            anchors { leftMargin: 18; rightMargin: 18; bottomMargin: 10 }
            contentHeight: contenido.height
            clip: true
            interactive: true

            Column {
                id: contenido
                width: scroll.width
                spacing: 18

                // ---- LOS GRUPOS ----
                //
                // UN Repeater sobre grupos con nombre libre (ADR-0020), no
                // dos bloques fijos "combos"/"codes". El estilo de cada
                // entrada NO lo decide el grupo: lo decide el CONTENIDO, via
                // Tokens.esSecuencia() — una secuencia corta de botones sale
                // como tarjeta numerada, una instruccion escrita sale como
                // renglon con ★. Asi un mismo grupo puede mezclar las dos
                // cosas, que es como vienen los trucos de verdad.
                Repeater {
                    model: root.grupos

                    Column {
                        width: parent.width
                        spacing: 10

                        readonly property var itemsGrupo: modelData.items

                        Seccion {
                            width: parent.width
                            etiqueta: modelData.label
                            contador: ("0" + itemsGrupo.length).slice(-2) + " ENTRADAS"
                            accent: root.accent
                        }

                        Repeater {
                            model: itemsGrupo

                            // UN delegate para las dos formas, no dos
                            // componentes: comparten estructura (marcador +
                            // nombre + tokens) y solo cambian el fondo y el
                            // marcador de la izquierda. Con dos Component
                            // declarados afuera habria que pasarles `index` y
                            // `modelData` a mano — un Component creado en la
                            // raiz NO ve el contexto del delegate.
                            Item {
                                width: parent.width
                                height: Math.max(esSec ? 56 : 44, tokens.height + (esSec ? 24 : 16))

                                readonly property bool esSec:
                                    Tokens.esSecuencia(modelData.input || "", "codigo")

                                // Solo la secuencia lleva tarjeta y barra de
                                // accent; la instruccion va sobre el fondo.
                                Rectangle {
                                    anchors.fill: parent
                                    visible: esSec
                                    color: Theme.alpha(root.accent, 0.05)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.textBright, 0.07)

                                    Rectangle {
                                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                        width: 3
                                        color: root.accent
                                    }
                                }

                                // El marcador: numero en caja para una
                                // secuencia, ★ para una instruccion.
                                Item {
                                    id: marcador
                                    anchors { left: parent.left; leftMargin: esSec ? 16 : 0 }
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: esSec ? 30 : 14
                                    height: 30

                                    Rectangle {
                                        anchors.fill: parent
                                        visible: esSec
                                        color: Theme.alpha(root.accent, 0.14)
                                        border.width: 1
                                        border.color: Theme.alpha(root.accent, 0.45)
                                        Text {
                                            anchors.centerIn: parent
                                            text: ("0" + (index + 1)).slice(-2)
                                            color: root.accent
                                            font.family: Theme.fontMono
                                            font.pixelSize: 12
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !esSec
                                        text: "★"
                                        color: root.accent
                                        font.pixelSize: 14
                                    }
                                }

                                Text {
                                    id: nombre
                                    anchors { left: marcador.right; leftMargin: 14 }
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 200
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    text: modelData.name || ""
                                    color: Theme.textPrimary
                                    font.family: Theme.fontBody
                                    font.pixelSize: 14
                                }

                                // Con ANCHORS sobre el Item, no con un Row: un
                                // Row saca su ancho de los hijos, y un hijo
                                // que quiera "el resto" cierra un circulo que
                                // QML no resuelve — dibuja todo encimado. Se
                                // vio en Pegasus el 2026-08-04.
                                InputTokenRow {
                                    id: tokens
                                    anchors { left: nombre.right; leftMargin: 14 }
                                    anchors { right: parent.right; rightMargin: esSec ? 16 : 0 }
                                    anchors.verticalCenter: parent.verticalCenter
                                    accent: root.accent
                                    tokens: Tokens.partir(modelData.input || "", "codigo")
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- pie ----------------------------------------------------------

        Text {
            id: pie
            anchors { bottom: parent.bottom; bottomMargin: 16 }
            anchors.horizontalCenter: parent.horizontalCenter
            // Nombrar UNA tecla es mentira la mitad del tiempo: este Pegasus
            // mapea `keys.cancel: Esc,Backspace,GamepadB` — la B es la del
            // gamepad, en teclado no existe. El gabinete va a tener joystick
            // y el Mac de desarrollo no, asi que se nombran las dos.
            // (El diseno asumia joystick y decia solo "B".)
            text: "— B · ESC PARA VOLVER —"
            color: Theme.textFaint
            font.family: Theme.fontMono
            font.pixelSize: Theme.sizeMonoSm
            font.letterSpacing: Theme.trackingLabel * Theme.sizeMonoSm

            SequentialAnimation on opacity {
                running: root.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 900 }
                NumberAnimation { to: 1.0; duration: 900 }
            }
        }
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            root.cerrar(); event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            scroll.contentY = Math.min(
                Math.max(0, scroll.contentHeight - scroll.height),
                scroll.contentY + 60);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            scroll.contentY = Math.max(0, scroll.contentY - 60);
            event.accepted = true;
        }
    }
}
