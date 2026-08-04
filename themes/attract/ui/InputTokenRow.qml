// Dibuja una secuencia de inputs ya tokenizada.
//
// NO PARSEA NADA. Recibe la lista que devuelve core/InputTokens.js y mapea
// tipo -> delegate. Ese corte es lo que permite verificar la gramatica sin
// abrir Pegasus (ver themes/experimentos/verificar-tokens.js).
//
// Es un Flow y no un Row porque una secuencia larga no entra en una linea:
// "↓ ↙ ← ↓ ↙ ← + PP" son ocho fichas.

import QtQuick 2.0
import QtGraphicalEffects 1.0
import ".."

Flow {
    id: root

    property var tokens: []
    property color accent: Theme.accentNeutro

    spacing: 6

    Repeater {
        model: root.tokens

        Loader {
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            sourceComponent: {
                switch (modelData.tipo) {
                case "direccion": return cDireccion;
                case "cara":      return cCara;
                case "gatillo":   return cGatillo;
                case "arcade":    return cArcade;
                case "keycap":    return cKeycap;
                case "mas":       return cMas;
                default:          return cTexto;
                }
            }
            property var tok: modelData
        }
    }

    // --- tecla de direccion: 36x36, flecha en accent ---
    Component {
        id: cDireccion
        Item {
            width: 36; height: 36
            Rectangle {
                id: teclaDir
                anchors.fill: parent
                radius: 9
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#1b1e26" }
                    GradientStop { position: 1.0; color: "#10121a" }
                }
                border.width: 1
                border.color: Theme.alpha(Theme.textBright, 0.14)
            }
            Text {
                anchors.centerIn: parent
                text: tok.valor
                color: root.accent
                font.pixelSize: 18
                font.bold: true
            }
            Glow {
                anchors.fill: teclaDir
                source: teclaDir
                radius: 8; samples: 9; spread: 0.1
                color: Theme.alpha(root.accent, 0.35)
                transparentBorder: true
                z: -1
            }
        }
    }

    // --- boton de cara: circulo con el color de la convencion ---
    Component {
        id: cCara
        Item {
            width: 34 + (tok.valor.length - 1) * 8
            height: 34
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#12141b"
                border.width: 2
                border.color: tok.color
            }
            Text {
                anchors.centerIn: parent
                text: tok.valor
                color: tok.color
                font.pixelSize: 14
                font.bold: true
            }
        }
    }

    // --- gatillo: pastilla con la etiqueta ---
    Component {
        id: cGatillo
        Rectangle {
            width: etiqGat.width + 24; height: 32
            radius: 8
            color: "#1b1e26"
            border.width: 1
            border.color: Theme.alpha(Theme.textBright, 0.16)
            Text {
                id: etiqGat
                anchors.centerIn: parent
                text: tok.valor
                color: "#dfe3ec"
                font.family: Theme.fontMono
                font.pixelSize: 12
                font.bold: true
            }
        }
    }

    // --- boton de arcade: circulo con degradado y bisel ---
    Component {
        id: cArcade
        Rectangle {
            width: 34 + (tok.valor.length - 1) * 7
            height: 34
            radius: height / 2
            gradient: Gradient {
                // El bisel del diseno: el claro arriba a la izquierda, como un
                // boton fisico iluminado desde arriba.
                GradientStop {
                    position: 0.0
                    color: Qt.lighter(tok.color, 1.55)
                }
                GradientStop { position: 1.0; color: tok.color }
            }
            Text {
                anchors.centerIn: parent
                text: tok.valor
                color: Theme.textBright
                font.family: Theme.fontDisplay
                font.pixelSize: 13
                font.bold: true
            }
        }
    }

    // --- keycap: tecla con relieve ---
    Component {
        id: cKeycap
        Rectangle {
            width: Math.max(27, etiqKey.width + 16); height: 28
            radius: 6
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#262b39" }
                GradientStop { position: 1.0; color: "#12141d" }
            }
            border.width: 1
            border.color: Theme.alpha(Theme.textBright, 0.18)
            Text {
                id: etiqKey
                anchors.centerIn: parent
                text: tok.valor
                color: "#eef0f6"
                font.family: Theme.fontDisplay
                font.pixelSize: 13
                font.bold: true
            }
        }
    }

    // --- el "+" entre inputs simultaneos: sin caja, es un separador ---
    Component {
        id: cMas
        Text {
            text: "+"
            color: "#5b6173"
            font.pixelSize: 16
            font.bold: true
        }
    }

    // --- prosa: lo que no es notacion se lee como texto ---
    Component {
        id: cTexto
        Text {
            text: tok.valor
            color: Theme.textBody
            font.family: Theme.fontBody
            font.pixelSize: 13
        }
    }
}
