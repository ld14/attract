// Los dos botones del diseno en un solo componente.
//
// El plan (spec/features/005-theme-base/plan.md) los listaba separados como
// AccentButton y GlassButton. Escribiendolos quedo claro que difieren en dos
// colores y en nada mas: mismo layout, mismo padding, mismo tratamiento de
// foco, mismo glifo opcional adelante. Dos archivos identicos salvo dos
// lineas es un archivo con una propiedad.
//
//   variant: "accent"  ->  fondo de accent, texto oscuro. El "▶ JUGAR".
//   variant: "glass"   ->  vidrio translucido, texto claro. El "▤ VER
//                          DETALLE" y el "◄ GALERIA".
//
// El foco NO es hover: el gabinete no tiene mouse. Se levanta y se le pone el
// anillo cuando `activo` es true, que lo maneja la pantalla que lo contiene.

import QtQuick 2.0
import ".."

Item {
    id: root

    property string texto: ""
    property string glifo: ""
    property string variant: "glass"      // "accent" | "glass"
    property color accent: Theme.accentNeutro
    property bool activo: false

    signal activado()

    readonly property bool _esAccent: variant === "accent"

    implicitWidth: fila.width + 48
    implicitHeight: 48

    // El "lift" del diseno: el boton enfocado sube unos pixeles.
    //
    // VA POR transform Y NO POR `y`, y no es un detalle de estilo: un Column
    // posiciona a sus hijos ESCRIBIENDOLES la y. Un binding sobre `y` pelea
    // con eso, gana el binding, y el boton se va a la posicion 0 - encima de
    // lo que tenga arriba. Pasa de a ratos, segun el orden en que se resuelva,
    // que es lo que lo hace dificil de ver. Se vio en Pegasus el 2026-08-03:
    // el boton JUGAR del detalle saltaba arriba de la caratula.
    //
    // Un transform no participa del layout, asi que el Column mantiene el
    // control y el efecto visual es el mismo.
    transform: Translate {
        y: root.activo ? -2 : 0
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        id: fondo
        anchors.fill: parent
        radius: Theme.radiusButton
        color: root._esAccent
               ? root.accent
               : (root.activo ? Theme.glassFillHi : Theme.glassFill)
        border.width: root._esAccent ? 0 : 1
        border.color: root.activo ? root.accent : Theme.glassBorder

        Behavior on color { ColorAnimation { duration: 180 } }
    }

    Row {
        id: fila
        anchors.centerIn: parent
        spacing: 10

        Text {
            visible: root.glifo !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.glifo
            color: root._esAccent ? Theme.textOnAccent : Theme.textPrimary
            font.family: Theme.fontBody
            font.pixelSize: 14
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.texto
            color: root._esAccent ? Theme.textOnAccent : Theme.textPrimary
            font.family: Theme.fontDisplay
            font.bold: true
            font.pixelSize: 16
            font.letterSpacing: 0.04 * 16
        }
    }

    FocusRing {
        accent: root._esAccent ? "#ffffff" : root.accent
        activo: root.activo
        radio: Theme.radiusButton
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.activado()
    }
}
