// El anillo de foco del diseno: un borde de accent mas un resplandor.
//
// Vive en su propio archivo aunque sea poca cosa, y esa decision se pago sola:
// el resplandor de verdad necesita QtGraphicalEffects, que no se sabia si
// existia en este binario de Pegasus. Se escribio primero como dos rectangulos
// concentricos, con el upgrade concentrado ACA. Cuando el experimento
// confirmo el modulo (themes/experimentos/graphical-effects.qml, 2026-08-03),
// el cambio fue este archivo y nada mas — no hubo que buscar veinte
// rectangulos repartidos por el theme.
//
// Cuesta GPU: cada Glow es una pasada extra. Se banca porque FocusRing solo
// se DIBUJA cuando `activo` (opacity 0 -> visible false), asi que hay uno o
// dos en pantalla a la vez, no uno por tarjeta del rail.

import QtQuick 2.0
import QtGraphicalEffects 1.0
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

    // El anillo. visible:false porque solo alimenta al Glow; el que se ve es
    // la copia de abajo.
    Rectangle {
        id: anillo
        anchors.fill: parent
        radius: root.radio
        color: "transparent"
        border.width: root.grosor
        border.color: root.accent
        visible: false
    }

    // "box-shadow: 0 0 40px <accent>" del diseno.
    Glow {
        anchors.fill: anillo
        source: anillo
        radius: 16
        samples: 17          // 2*radius+1 acotado: mas no se nota y cuesta
        spread: 0.2
        color: root.accent
        transparentBorder: true
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radio
        color: "transparent"
        border.width: root.grosor
        border.color: root.accent
    }
}
