// Las tarjetas de CONTENIDO EXTRA del detalle: Hacks (trucos y combos) y
// Manual digitalizado.
//
// LAS REVISTAS NO ESTAN ACA A PROPOSITO. El handoff es explicito: viven solo
// en el carrusel de la columna izquierda, no se duplican como tarjeta. Ese
// carrusel llega con la feature 006.
//
// DIVERGENCIA CONSCIENTE RESPECTO DEL HANDOFF: el handoff omite la tarjeta
// cuando el juego no tiene ese contenido, y muestra una fila punteada solo
// cuando no tiene NINGUNO. CONVENCION #2.3 dice lo contrario y gana: las dos
// tarjetas estan siempre, y la que no tiene contenido dice "No Disponible".
// El motivo es que la estructura de la pantalla no cambie de juego en juego —
// que el ojo encuentre las cosas en el mismo lugar siempre. Consecuencia: la
// fila punteada del handoff no existe, porque su caso nunca se da.

import QtQuick 2.0
import ".."
import "../ui"

Column {
    id: root

    property var datos: null
    property color accent: Theme.accentNeutro
    property int foco: -1               // indice enfocado, -1 = ninguno

    signal abrir(string tipo)

    spacing: 12

    SectionLabel {
        text: "CONTENIDO EXTRA"
        activo: root.foco >= 0
        accent: root.accent
    }

    Row {
        spacing: 14

        Repeater {
            model: [
                {
                    tipo: "cheats",
                    glifo: "☠",
                    etiqueta: "Hacks",
                    hay: root.datos ? root.datos.hayCheats : false,
                    sub: root.datos ? root._subCheats() : ""
                },
                {
                    tipo: "manual",
                    glifo: "❐",
                    etiqueta: "Manual digitalizado",
                    hay: root.datos ? root.datos.hayManual : false,
                    sub: (root.datos && root.datos.hayManual)
                         ? root.datos.manualPaginas + " págs" : ""
                }
            ]

            Item {
                id: tarjeta
                width: 250
                height: 66

                readonly property bool enfocada: root.foco === index
                readonly property bool disponible: modelData.hay

                // Por transform y no por `y`: un Row tambien escribe la y de
                // sus hijos. Mismo motivo que en ui/Boton.qml.
                transform: Translate {
                    y: tarjeta.enfocada ? -3 : 0
                    Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusCard
                    color: tarjeta.enfocada ? Theme.glassFillHi : Theme.glassFill
                    border.width: 1
                    border.color: tarjeta.enfocada ? root.accent : Theme.glassBorder
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                Row {
                    anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                    spacing: 14

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 50; height: 50
                        radius: Theme.radiusChip
                        color: Theme.alpha(root.accent, tarjeta.disponible ? 0.14 : 0.05)
                        border.width: 1
                        border.color: Theme.alpha(root.accent, tarjeta.disponible ? 0.45 : 0.15)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.glifo
                            color: tarjeta.disponible ? root.accent : Theme.textFaint
                            font.pixelSize: 22
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: modelData.etiqueta
                            color: tarjeta.disponible ? Theme.textPrimary : Theme.textFaint
                            font.family: Theme.fontBody
                            font.pixelSize: Theme.sizeLabel
                        }

                        Text {
                            // El bloque no desaparece: dice que no hay (§2.3).
                            text: tarjeta.disponible ? modelData.sub : "No Disponible"
                            color: Theme.textFaint
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.sizeMonoSm
                        }
                    }
                }

                Text {
                    anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                    text: "›"
                    color: tarjeta.disponible ? Theme.textMuted : Theme.textFaint
                    font.pixelSize: 18
                }

                MouseArea {
                    anchors.fill: parent
                    // Una tarjeta sin contenido se ve, pero no se abre: no hay
                    // nada del otro lado.
                    enabled: tarjeta.disponible
                    onClicked: root.abrir(modelData.tipo)
                }
            }
        }
    }

    function _subCheats() {
        if (!datos || !datos.hayCheats) return "";
        var p = [];
        if (datos.combosCount) p.push(datos.combosCount + " combos");
        if (datos.codesCount) p.push(datos.codesCount + " trucos");
        return p.join("  ·  ");
    }
}
