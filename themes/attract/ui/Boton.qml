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

    // La tecla que hace lo mismo que este boton, dibujada adentro como un
    // keycap. No es decoracion: en un gabinete sin teclado ni mouse es la
    // unica forma de descubrir que X abre el orden y que Y abre Buscar
    // (design_handoff_home/README.md §Top bar). "" lo oculta.
    property string atajo: ""

    // El prototipo usa 8px de radio para casi todo (BUSCAR, "?", CERRAR,
    // VOLVER — Pegasus Home.dc.html:84,223,278,785) y reserva 10px solo para
    // el CTA grande del detalle, "JUGAR EN" (:289). Theme.radiusButton = 10
    // es el default historico de este componente porque el primer lugar
    // donde se uso fue justo ese boton grande; se deja como default para no
    // tocar los llamados existentes, y las pantallas que necesiten el 8 del
    // prototipo lo pasan explicito. Auditoria de fidelidad, 2026-08-08.
    property int radio: Theme.radiusButton

    signal activado()

    readonly property bool _esAccent: variant === "accent"

    // padding 11px 20px del prototipo (Pegasus Home.dc.html:107). Antes eran
    // 48 de alto y 24 de padding lateral, sacados del mockup viejo: el boton
    // se veia notoriamente mas grande que en el diseño.
    implicitWidth: fila.width + 40
    implicitHeight: 40

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
        radius: root.radio
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
            visible: root.texto !== ""
            text: root.texto
            color: root._esAccent ? Theme.textOnAccent : Theme.textPrimary
            font.family: Theme.fontDisplay
            font.bold: true
            font.pixelSize: 14
            font.letterSpacing: 0.04 * 14
        }

        // El keycap del atajo. Sobre vidrio va RELLENO DE ACCENT con texto
        // oscuro, como la pastilla BUSCAR del prototipo (:81); sobre un boton
        // que ya es de accent no se puede, asi que ahi se oscurece.
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.atajo !== ""
            width: tecla.implicitWidth + 10
            height: tecla.implicitHeight + 4
            radius: 4
            color: root._esAccent ? Theme.alpha(Theme.textOnAccent, 0.20)
                                  : root.accent

            Text {
                id: tecla
                anchors.centerIn: parent
                text: root.atajo
                color: Theme.textOnAccent
                font.family: Theme.fontMono
                font.bold: true
                font.pixelSize: 9
            }
        }
    }

    FocusRing {
        accent: root._esAccent ? "#ffffff" : root.accent
        activo: root.activo
        radio: root.radio
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.activado()
    }
}
