// Las pastillas de metadata del diseno: "AÑO 1992", "SISTEMA Arcade",
// "GENERO Fighting". Clave en gris apagado, valor en blanco.
//
// Tambien cubre el pill del sistema en el eyebrow del hero, que lleva borde y
// texto en accent y no tiene clave — de ahi que `clave` sea opcional y
// `resaltado` exista.
//
// El valor NUNCA queda vacio: si no hay dato muestra "Sin Informacion", que
// es la regla de CONVENCION #2.3. La regla vive aca y no en cada pantalla
// para que no se olvide en una.

import QtQuick 2.0
import ".."

Item {
    id: root

    property string clave: ""
    property string valor: ""
    property bool resaltado: false          // borde y texto en accent
    property color accent: Theme.accentNeutro

    // "Sin Informacion" es para bloques de TEXTO. Los de juegos/trucos/
    // manuales usan "No Disponible" - la distincion es de #2.3, no un detalle.
    property string vacio: "Sin Informacion"

    readonly property string _valor: valor !== "" ? valor : vacio
    readonly property bool _sinDato: valor === ""

    implicitWidth: fila.width + 24
    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.glassFill
        border.width: 1
        border.color: root.resaltado ? root.accent : Theme.glassBorder
    }

    Row {
        id: fila
        anchors.centerIn: parent
        spacing: 7

        Text {
            visible: root.clave !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.clave
            color: Theme.textFaint
            font.family: Theme.fontMono
            font.pixelSize: 11
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root._valor
            // Sin dato se ve mas apagado: la pastilla sigue ahi, pero no
            // compite con las que si tienen informacion.
            color: root._sinDato ? Theme.textFaint
                                 : (root.resaltado ? root.accent : Theme.textPrimary)
            font.family: Theme.fontMono
            font.pixelSize: 11
        }
    }
}
