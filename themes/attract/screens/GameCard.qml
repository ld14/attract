// Una tarjeta del rail de la libreria. 148x166, radio 10.
//
// OJO CON UNA COSA QUE SORPRENDE: la tarjeta NO muestra la caratula. El
// diseno la quiere tenida con el accent del juego y con el titulo encima
// (docs/mockup-referencia.html, libGames + coverBg). La caratula aparece
// recien en el detalle, como box art. No es un olvido: son cartas de color
// que se leen de un vistazo, no una grilla de cajas.
//
// Cada tarjeta trae su PROPIO GameData, porque el accent es por juego
// (ADR-0013) y el diseno tine cada tarjeta con el suyo. Eso significa una
// lectura de data.json por tarjeta — sostenible porque el rail es un
// ListView (solo existen las visibles) y porque el cache es compartido
// (core/DataCache.js), asi que scrollear ida y vuelta no relee nada.

import QtQuick 2.0
import ".."
import "../core"
import "../ui"

Item {
    id: root

    property var game: null
    property bool activo: false
    property int variacion: 0

    signal activado()

    // El accent de ESTA tarjeta, para que el rail lo lea sin duplicar el
    // GameData (la pantalla lo necesita para el hero y el fondo).
    readonly property color accent: datos.accent
    readonly property alias estado: datos.estado

    property var paths: null

    width: 148
    height: 166

    GameData {
        id: datos
        game: root.game
        paths: root.paths
    }

    // El "lift" del diseno: la enfocada sube y crece; las demas se apagan.
    transform: Translate { y: root.activo ? -14 : 0 }
    scale: root.activo ? 1.06 : 1.0
    opacity: root.activo ? 1.0 : 0.5

    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 300 } }

    Item {
        id: cuerpo
        anchors.fill: parent

        AccentWash {
            anchors.fill: parent
            accent: root.accent
            accent2: datos.accent2
            variacion: root.variacion
        }

        // Redondeo: Qt Quick 5.15 no tiene border-radius sobre un Canvas sin
        // OpacityMask (QtGraphicalEffects, sin verificar). Se aproxima con un
        // marco del color del fondo por encima — se ve igual sobre un fondo
        // oscuro, que es el unico caso que existe aca.
        Rectangle {
            anchors.fill: parent
            radius: 10
            color: "transparent"
            border.width: 3
            border.color: Theme.screen
        }

        Column {
            anchors.fill: parent
            anchors.margins: 13
            spacing: 0

            // fila de arriba: sistema + año
            Text {
                width: parent.width
                elide: Text.ElideRight
                color: Theme.textPrimary
                font.family: Theme.fontMono
                font.pixelSize: 9
                font.letterSpacing: 0.1 * 9
                text: {
                    var col = (root.game && root.game.collections
                               && root.game.collections.count > 0)
                              ? root.game.collections.get(0).name : "";
                    // releaseYear vuelve 0 cuando no hay release: — es "sin
                    // dato", no el año cero (medido 2026-08-02).
                    var anio = (root.game && root.game.releaseYear > 0)
                               ? String(root.game.releaseYear) : "";
                    return [col.toUpperCase(), anio].filter(function(s) {
                        return s !== "";
                    }).join("  ·  ");
                }
            }

            Item { width: 1; height: parent.height - 14 - 44 }

            // abajo: titulo + puntos de contenido
            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                color: Theme.textBright
                font.family: Theme.fontDisplay
                font.bold: true
                font.pixelSize: 15
                lineHeight: 1.1
                text: root.game ? root.game.title : ""
            }

            Item { width: 1; height: 7 }

            // Un punto por tipo de contenido extra. Es el unico lugar de la
            // libreria donde se ve que un juego tiene revistas, trucos o
            // manual sin entrar al detalle.
            Row {
                spacing: 5
                Repeater {
                    model: [datos.hayRevistas, datos.hayCheats, datos.hayManual]
                    Rectangle {
                        visible: modelData
                        width: 7; height: 7; radius: 3.5
                        color: root.activo ? root.accent : Theme.alpha(Theme.textBright, 0.5)
                    }
                }
            }
        }
    }

    FocusRing {
        accent: root.accent
        activo: root.activo
        radio: 10
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.activado()
    }
}
