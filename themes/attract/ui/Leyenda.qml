// La barra de atajos del pie. Cada pantalla publica su lista y esto la dibuja.
//
// POR QUE ES DINAMICA Y NO UNA LISTA FIJA: el handoff la pide reflejando "los
// atajos validos para la region/pantalla activa", y esa es toda su razon de
// existir. En un gabinete sin teclado ni mouse, esta barra es el UNICO lugar
// donde se descubre que X abre el orden y que Y abre Buscar. Una leyenda que
// miente —que nombra una tecla que en ese contexto no hace nada— es peor que
// no tenerla: ya paso una vez con el pie del visor de documentos (commit
// a257c46, "el pie nombraba una tecla que el teclado no tiene").
//
// El modelo es [{ k, l }]: k es el glifo del boton, l lo que hace.
//
// LOS VALORES SALEN DEL PROTOTIPO, no de mirar una captura (Pegasus Home.dc.html
// :345-350): la tecla es un keycap RELLENO DE ACCENT con texto oscuro, no una
// pastilla de vidrio. Ese contraste es lo que la hace leerse de lejos en un
// gabinete, que es el unico lugar donde alguien la va a leer.

import QtQuick 2.0
import ".."

Row {
    id: root

    property var atajos: []
    property color accent: Theme.accentNeutro

    spacing: 26

    Repeater {
        model: root.atajos

        Row {
            spacing: 8

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: glifo.implicitWidth + 16      // padding 3px 8px
                height: glifo.implicitHeight + 6
                radius: 5
                color: root.accent

                Text {
                    id: glifo
                    anchors.centerIn: parent
                    text: modelData.k
                    color: Theme.textOnAccent
                    font.family: Theme.fontMono
                    font.bold: true
                    font.pixelSize: 10
                    font.letterSpacing: 0.04 * 10
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.l
                // #9aa0b0 del prototipo (:349) — parecido a Theme.textMuted
                // (#8a90a0) pero NO es el mismo token, y ahi no van digitos
                // permutados por descuido: es el color puntual de la leyenda.
                color: "#9aa0b0"
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.letterSpacing: 0.04 * 11
            }
        }
    }
}
