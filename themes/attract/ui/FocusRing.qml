// El anillo de foco del diseno: un borde de accent mas un resplandor.
//
// Vive en su propio archivo aunque sean tres rectangulos, por una razon
// concreta: el resplandor de verdad necesita QtGraphicalEffects, y todavia no
// sabemos si ese modulo existe en este binario de Pegasus (ver
// themes/experimentos/graphical-effects.qml, sin correr). Cuando se responda,
// el upgrade se hace ACA y lo heredan todos los estados de foco del theme, en
// vez de haber que buscar veinte rectangulos repartidos.
//
// ponytail: aproximacion plana mientras tanto - dos rectangulos concentricos
// con opacidad decreciente en vez de un blur real. Se ve mas duro que el
// "box-shadow: 0 0 40px accent" del CSS, pero no cuesta GPU en el gabinete y
// no depende de ningun modulo. Si graphical-effects.qml resuelve, reemplazar
// el halo por un Glow.

import QtQuick 2.0
import ".."

Item {
    id: root

    property color accent: Theme.accentNeutro
    property bool activo: false
    property int radio: Theme.radiusCard
    property int grosor: 2

    anchors.fill: parent
    visible: opacity > 0
    opacity: activo ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 180 } }

    // halo exterior (la aproximacion al glow)
    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        radius: root.radio + 6
        color: "transparent"
        border.width: 6
        border.color: Theme.alpha(root.accent, 0.18)
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: root.radio + 2
        color: "transparent"
        border.width: 2
        border.color: Theme.alpha(root.accent, 0.40)
    }

    // el anillo propiamente dicho
    Rectangle {
        anchors.fill: parent
        radius: root.radio
        color: "transparent"
        border.width: root.grosor
        border.color: root.accent
    }
}
