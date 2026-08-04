// Las cinco barras de volumen del transporte de video.
//
// Se llenan en proporcion al volumen; con mute, ninguna. Es lo que hace que el
// estado del audio se lea de un vistazo sin numeros — importante en un
// gabinete, donde nadie se acerca a leer un "0.60".

import QtQuick 2.0
import ".."

Row {
    id: root

    property real volumen: 0        // 0.0 a 1.0
    property bool muteado: false
    property color accent: Theme.accentNeutro

    spacing: 3

    readonly property int _encendidas: muteado ? 0 : Math.round(volumen * 5)

    Repeater {
        model: 5
        Rectangle {
            width: 5
            height: 13
            radius: 1
            color: index < root._encendidas ? root.accent
                                            : Theme.alpha(Theme.textBright, 0.22)
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }
}
