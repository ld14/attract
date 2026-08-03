// Las etiquetas de seccion del diseno: "SINOPSIS", "NOTAS EN REVISTAS",
// "CONTENIDO EXTRA". Mono, chicas, muy espaciadas.
//
// Se ponen en accent cuando la seccion que encabezan tiene el foco — es como
// el diseno indica donde esta parado el usuario sin mover nada de lugar.

import QtQuick 2.0
import ".."

Text {
    id: root

    property bool activo: false
    property color accent: Theme.accentNeutro

    color: activo ? accent : Theme.textMuted
    font.family: Theme.fontMono
    font.pixelSize: Theme.sizeMonoSm
    font.letterSpacing: Theme.trackingLabel * Theme.sizeMonoSm

    Behavior on color { ColorAnimation { duration: 180 } }
}
