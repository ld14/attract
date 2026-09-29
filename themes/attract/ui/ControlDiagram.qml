// Diagrama de controles de la guia "Como se juega" (feature 028).
//
// Dibuja SOLO con Rectangle/Text/Repeater - QtQuick.Shapes seria un import
// nuevo, y un import que no resuelve tumba el theme entero
// (docs/plataforma-pegasus.md #1).
//
// SIN CORRESPONDENCIA VERIFICADA (el estado de hoy: Gabinete.algunaPosicionMedida
// es siempre false, panel en transicion) esto NUNCA posiciona un boton en una
// celda fisica del panel: lista las acciones como fichas sueltas, con su
// entrada logica. Resolver A CUAL posicion fisica corresponde cada control es
// trabajo de la Etapa F (docs/como-se-juega.md, "Condicion de exito"), que
// hoy no tiene ningun dato con que operar - no se construye una resolucion
// que no puede hacer nada todavia.
//
// "SIN USO" vs "ACCION DESCONOCIDA" (criterio de aceptacion de la spec): son
// cruces automaticos contra `controlesDeclarados` (lo que -listxml dice que
// el juego tiene), no contra el panel fisico:
//   - un boton que el juego declara pero `acciones` no menciona -> "Sin uso".
//   - una accion cuyo control no encaja con ningun boton declarado para ese
//     jugador -> "Acción desconocida" (dato inconsistente, ej. P1_BUTTON9 en
//     un juego de 4 botones).
// Los controles de periferico (trackball/dial/paddle/lightgun) NO entran acá:
// eso lo resuelve GuideOverlay como requisito, no como boton (spec 027/028).

import QtQuick 2.0
import ".."
import "../core/ControlDiagram.js" as Diagrama

Column {
    id: root

    property var acciones: []            // GameData.guiaAcciones
    property var controlesDeclarados: [] // Correspondencia.controlesDeclarados
    property color accent: Theme.accentNeutro

    spacing: 14

    readonly property var _colorPorNombre: ({
        "Red": "#e0453f", "Blue": "#3f7fe0", "Yellow": "#e0c53f",
        "Green": "#3fe07a", "White": "#e8e8ec", "Black": "#2a2c33",
        "Orange": "#e08a3f", "Purple": "#a13fe0", "Pink": "#e03fb0"
    })

    function _colorDe(nombre) {
        return (nombre && root._colorPorNombre[nombre]) ? root._colorPorNombre[nombre] : root.accent;
    }

    // Cuantos botones declara -listxml para el jugador 1 (el unico instalado
    // hoy, ver gabinete.json). 0 si no hay dato - la fila de botones
    // simplemente no se dibuja. La logica de clasificacion vive en
    // core/ControlDiagram.js, testeada con node (tests/test_control_diagram.cjs).
    readonly property int _botonesJugador1: Diagrama.botonesDeclarados(controlesDeclarados, "1")
    readonly property var _accionesPorBoton: Diagrama.accionesPorBoton(acciones, "1")
    readonly property var _direcciones: Diagrama.direcciones(acciones, "1")
    readonly property var _desconocidas: Diagrama.desconocidas(acciones, root._botonesJugador1, "1")

    // --- botones numerados: "Sin uso" el que no tiene accion declarada ---
    Row {
        spacing: 10
        visible: root._botonesJugador1 > 0

        Repeater {
            model: root._botonesJugador1

            Column {
                spacing: 6
                readonly property var _accion: root._accionesPorBoton[index + 1]

                Rectangle {
                    width: 44; height: 44
                    radius: height / 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: parent._accion ? root._colorDe(parent._accion.color) : "#1b1e26"
                    border.width: 1
                    border.color: Theme.alpha(Theme.textBright, 0.18)

                    Text {
                        anchors.centerIn: parent
                        text: String(index + 1)
                        color: parent.parent._accion ? Theme.textBright : Theme.textFaint
                        font.bold: true
                        font.pixelSize: 15
                    }
                }

                Text {
                    width: 78
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: parent._accion ? parent._accion.action : "Sin uso"
                    color: parent._accion ? Theme.textBody : Theme.textFaint
                    font.family: Theme.fontBody
                    font.pixelSize: 11
                }
            }
        }
    }

    // --- palanca: solo las direcciones que la guia declaro ---
    Row {
        spacing: 16
        visible: root._direcciones.length > 0

        Repeater {
            model: root._direcciones

            Row {
                spacing: 6
                Text {
                    text: modelData.dir === "UP" ? "↑" : modelData.dir === "DOWN" ? "↓"
                        : modelData.dir === "LEFT" ? "←" : "→"
                    color: root.accent
                    font.pixelSize: 18
                    font.bold: true
                }
                Text {
                    text: modelData.accion.action
                    color: Theme.textBody
                    font.family: Theme.fontBody
                    font.pixelSize: 12
                }
            }
        }
    }

    // --- acciones desconocidas: estilo de alerta, a proposito distinto ---
    Column {
        spacing: 4
        visible: root._desconocidas.length > 0

        Repeater {
            model: root._desconocidas

            Row {
                spacing: 8
                Rectangle {
                    width: 8; height: 8; radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#e0453f"
                }
                Text {
                    text: modelData.action + "  (" + modelData.control + " · acción desconocida)"
                    color: "#e0453f"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
            }
        }
    }
}
