// EXPERIMENTO — ¿existe QtGraphicalEffects en el binario oficial de Pegasus?
//
// Contexto: el diseño de design_handoff_game_detail/ se apoya fuerte en tres
// efectos que CSS da gratis y Qt Quick puro no tiene:
//   - "backdrop-filter: blur(16px)"  detrás del visor de documentos
//   - "box-shadow: 0 0 40px <accent>" (glow del accent en foco y botones)
//   - "box-shadow: 0 20-40px 60-120px rgba(0,0,0,.6)" (sombras grandes)
// El handoff dice explícitamente que se aproximen con FastBlur/GaussianBlur
// "(Qt5Compat.GraphicalEffects o MultiEffect de Qt6)". Pero ADR-0006 fija
// Qt 5.15: Qt5Compat y MultiEffect son Qt6, no aplican. El módulo Qt5 que
// haría el trabajo es QtGraphicalEffects.
//
// El problema: ADR-0007 y docs/decisiones/2026-07-23.md (punto 3) documentan
// que las dependencias de build declaradas de Pegasus son solo QML/QtQuick2,
// Multimedia, SVG y SQL. QtGraphicalEffects NO está en esa lista — igual que
// PDF, que efectivamente no existía. Puede estar igual (arrastrado como
// dependencia transitiva de Qt) o puede no estar.
//
// Esto NO es un detalle de implementación: define si el theme puede tener
// blur y glow de verdad o si hay que aproximar todo con Rectangles planos
// translúcidos. Cambia el diseño, no solo el código.
//
// PREDICCIÓN: incierto, a diferencia del experimento de PDF. QtGraphicalEffects
// es parte de Qt 5.15 estándar (no un módulo raro como QtQuick.Pdf, que en Qt5
// era tech preview), así que hay chance de que venga incluido aunque no esté
// declarado. Si NO está, el síntoma va a ser el mismo que con PDF: Pegasus ni
// carga el theme ("Theme loading failed :("), porque el import no resuelve.
//
// RESULTADO OBSERVADO: <PENDIENTE — correr contra Pegasus real y anotar acá>
//
// Cómo leer el resultado — hay TRES desenlaces distintos, no dos:
//   a) "Theme loading failed"        -> el módulo NO existe. Sin blur ni glow.
//   b) carga y se ven los 3 efectos  -> el módulo existe y funciona.
//   c) carga pero algún panel se ve  -> existe pero un efecto puntual falla;
//      negro/vacío                      anotá CUÁL, no alcanza con "anda".
//
// Cómo correrlo:
//   1. cp graphical-effects.qml <themes de Pegasus>/attract-debug/theme.qml
//   2. abrí Pegasus y mirá cuál de los tres desenlaces pasa
//   3. anotá arriba el resultado
//
// Se importa la version 1.0 a proposito (no 1.15): es la mas vieja y la mas
// probable de resolver. Los tres efectos que se prueban existen desde 1.0.

import QtQuick 2.0
import QtGraphicalEffects 1.0

FocusScope {
    id: root
    focus: true

    Rectangle { anchors.fill: parent; color: "#0d1117" }

    property color accent: "#3ad17a"

    Text {
        id: titulo
        anchors { top: parent.top; left: parent.left; margins: 40 }
        color: "#7ee787"
        font.family: "monospace"
        font.pixelSize: 16
        text: "=== QtGraphicalEffects ===\nSi ves esto, el import RESOLVIO.\nAhora fijate si los 3 paneles de abajo se ven bien."
    }

    Row {
        anchors.centerIn: parent
        spacing: 60

        // --- 1. Glow: el resplandor de accent en los estados de foco ---
        Item {
            width: 200; height: 200
            Rectangle {
                id: fuenteGlow
                anchors.centerIn: parent
                width: 120; height: 120; radius: 12
                color: root.accent
                visible: false          // solo alimenta al efecto
            }
            Glow {
                anchors.fill: fuenteGlow
                source: fuenteGlow
                radius: 24
                samples: 25
                color: root.accent
            }
            Rectangle {
                anchors.fill: fuenteGlow
                radius: 12
                color: root.accent
            }
            Text {
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                color: "#8a90a0"; font.family: "monospace"; font.pixelSize: 12
                text: "1. Glow"
            }
        }

        // --- 2. DropShadow: las sombras grandes de los paneles elevados ---
        Item {
            width: 200; height: 200
            Rectangle {
                id: fuenteSombra
                anchors.centerIn: parent
                width: 120; height: 120; radius: 12
                color: "#1b1e26"
                visible: false
            }
            DropShadow {
                anchors.fill: fuenteSombra
                source: fuenteSombra
                horizontalOffset: 0
                verticalOffset: 20
                radius: 40
                samples: 41
                color: "#aa000000"
            }
            Rectangle {
                anchors.fill: fuenteSombra
                radius: 12
                color: "#1b1e26"
            }
            Text {
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                color: "#8a90a0"; font.family: "monospace"; font.pixelSize: 12
                text: "2. DropShadow"
            }
        }

        // --- 3. FastBlur sobre contenido vivo: el backdrop-filter del visor ---
        // Este es el caso mas exigente: no borronea un color plano, borronea
        // otro Item que tiene textura. Es lo que haria falta detras del visor.
        Item {
            width: 200; height: 200
            Item {
                id: fuenteBlur
                anchors.centerIn: parent
                width: 120; height: 120
                visible: false
                Rectangle { anchors.fill: parent; color: "#0a0c12" }
                Grid {
                    anchors.centerIn: parent
                    columns: 4; spacing: 6
                    Repeater {
                        model: 16
                        Rectangle {
                            width: 20; height: 20; radius: 4
                            color: index % 2 === 0 ? root.accent : "#ff5a3c"
                        }
                    }
                }
            }
            FastBlur {
                anchors.fill: fuenteBlur
                source: fuenteBlur
                radius: 32
            }
            Text {
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                color: "#8a90a0"; font.family: "monospace"; font.pixelSize: 12
                text: "3. FastBlur"
            }
        }
    }

    Text {
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 40 }
        color: "#6a7081"
        font.family: "monospace"
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        text: "1 = cuadrado verde con halo alrededor\n" +
              "2 = cuadrado gris con sombra grande abajo\n" +
              "3 = cuadricula de colores BORRONEADA (no nitida, no negra)"
    }
}
