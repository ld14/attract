// Una tarjeta de estante. 148x166, radio 10.
//
// AHORA MUESTRA LA CARATULA REAL, y eso REVIERTE lo que decia el encabezado
// anterior de este archivo. El mockup viejo pedia cartas tenidas con el
// accent y el titulo encima; el handoff nuevo pide la caratula de fondo con
// un velo oscuro abajo para que el texto se lea (design_handoff_home/
// README.md §Estantes). El wash de color no se borro: es el ultimo eslabon de
// CoverImage cuando el juego no tiene ninguna imagen, que con fixtures/ en 0
// bytes sigue siendo el caso mas comun. O sea que en el gabinete se ven las
// dos cosas, cada una donde corresponde.
//
// Cada tarjeta trae su PROPIO GameData, porque el accent es por juego
// (ADR-0013) y tiñe el anillo de foco y los puntos de contenido. Eso es una
// lectura de data.json por tarjeta, sostenible por dos motivos medidos: el
// estante es un ListView y solo existen las visibles (pico de 47 delegates
// con cuatro estantes de 1200, themes/experimentos/estantes-perf.qml), y el
// cache es compartido (core/DataCache.js), asi que un juego que aparece en
// cuatro estantes a la vez pide el archivo una sola vez.

import QtQuick 2.0
import QtGraphicalEffects 1.0
import ".."
import "../core"
import "../ui"

Item {
    id: root

    property var game: null
    property var paths: null

    property bool activo: false      // es la tarjeta enfocada de SU estante
    property bool atenuado: false    // su estante no es el estante enfocado
    property int variacion: 0

    // -1 = sin ranking. Solo lo pone el estante MAS JUGADOS.
    property int rango: -1

    // -1 = sin barra. Solo lo pone CONTINUAR JUGANDO, y NO es un porcentaje
    // de juego completado: es playTime relativo al mas jugado del estante.
    // Pegasus no expone nada parecido a un progreso de partida (el `prog` del
    // handoff no tiene contraparte en la API).
    property real progreso: -1

    signal activado()

    readonly property color accent: datos.accent
    readonly property alias estado: datos.estado

    width: 148
    height: 166

    GameData {
        id: datos
        game: root.game
        paths: root.paths
    }

    // El "lift" del diseño. Va por transform y NO por un binding sobre `y`:
    // el ListView posiciona a sus delegates escribiendoles la coordenada, y un
    // binding ahi pelea con el layout y gana a veces (docs/plataforma-pegasus.md
    // §3, primera fila de la tabla).
    transform: Translate { y: root.activo ? -12 : 0 }
    scale: root.activo ? 1.05 : 1.0

    // Tres niveles, como pide el handoff: la enfocada entera, sus vecinas del
    // mismo estante al 62%, y las de los otros estantes al 50%.
    opacity: root.activo ? 1.0 : (root.atenuado ? 0.50 : 0.62)

    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 300 } }

    Item {
        anchors.fill: parent

        // caratula+velo van en un grupo aparte, INVISIBLE, que solo alimenta
        // al OpacityMask de abajo. Antes se aproximaba el redondeo con un
        // marco de 3px del color del fondo por encima — y ESE truco esta
        // roto contra una caratula real: el marco es un TRAZO fino sobre el
        // path redondeado, no un relleno, asi que el triangulo de esquina
        // entre el trazo y la esquina cuadrada de la imagen queda SIN cubrir
        // y la caratula asoma con esquina recta. Se ve claro en cualquier
        // caratula con color hasta el borde (Street Fighter, Tekken 3 —
        // visto en Pegasus el 2026-08-09). QtGraphicalEffects SI esta
        // confirmado en este binario (themes/experimentos/graphical-effects.qml,
        // 2026-08-03) y ya lo usa ui/FocusRing.qml; OpacityMask recorta de
        // verdad, no aproxima.
        Item {
            id: caratula
            anchors.fill: parent
            visible: false

            CoverImage {
                anchors.fill: parent
                game: root.game
                accent: datos.accent
                accent2: datos.accent2
                variacion: root.variacion
            }

            // El velo del handoff: sin esto el titulo blanco sobre una
            // caratula clara no se lee. Los cortes son los del prototipo
            // (:137): transparente hasta el 38%, negro .8 al pie.
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.00; color: "transparent" }
                    GradientStop { position: 0.38; color: "transparent" }
                    GradientStop { position: 1.00; color: Qt.rgba(0, 0, 0, 0.80) }
                }
            }
        }

        Rectangle {
            id: mascaraRedondeo
            anchors.fill: parent
            radius: 10
            visible: false
        }

        // ponytail: OpacityMask corre POR TARJETA VISIBLE (hasta ~47 a la
        // vez medido, themes/experimentos/estantes-perf.qml), no solo en la
        // enfocada como el Glow de FocusRing — es mas costo de GPU del que
        // ese archivo aprueba para el rail. Se banca por ahora porque el
        // bug que reemplaza (esquinas cuadradas asomando) es visible y real;
        // si el gabinete lo nota, medir contra Pegasus real antes de sacarlo.
        OpacityMask {
            anchors.fill: parent
            source: caratula
            maskSource: mascaraRedondeo
        }

        // padding 11px, como el prototipo (:666).
        Item {
            anchors.fill: parent
            anchors.margins: 11

            // --- arriba: el ranking a la izquierda y SOLO el año a la derecha.
            // El sistema no va aca: en el diseño baja como chip junto al
            // titulo. Con anchors y no con un Row porque el texto de la
            // derecha necesita saber cuanto le queda, y un hijo de Row que
            // depende del ancho del Row cierra un circulo que QML no resuelve
            // (docs/plataforma-pegasus.md §3, ultima fila).
            Text {
                id: numero
                anchors { top: parent.top; left: parent.left }
                anchors { topMargin: -3; leftMargin: -2 }
                visible: root.rango > 0
                text: ("0" + root.rango).slice(-2)
                color: Theme.textBright
                font.family: Theme.fontDisplay
                font.bold: true
                font.pixelSize: 22
                lineHeight: 0.8
                opacity: 0.92
            }

            Text {
                anchors { top: parent.top; right: parent.right }
                // releaseYear vuelve 0 cuando no hay release: — es "sin dato",
                // no el año cero (medido 2026-08-02).
                text: (root.game && root.game.releaseYear > 0)
                      ? String(root.game.releaseYear) : ""
                color: Theme.alpha(Theme.textBright, 0.62)
                font.family: Theme.fontMono
                font.pixelSize: 9
            }

            // --- abajo: chips, titulo, puntos de contenido y la barra
            Column {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                spacing: 6

                // El sistema como chip oscuro sobre la caratula, que es donde
                // el diseño lo pone (:145). Sobre arte claro un texto suelto no
                // se lee; el chip le pone su propio fondo.
                Row {
                    spacing: 4

                    Rectangle {
                        visible: sistema.text !== ""
                        width: sistema.implicitWidth + 8
                        height: sistema.implicitHeight + 2
                        radius: 3
                        color: Qt.rgba(0, 0, 0, 0.45)
                        border.width: 1
                        border.color: Theme.alpha(Theme.textBright, 0.22)

                        Text {
                            id: sistema
                            anchors.centerIn: parent
                            text: (root.game && root.game.collections
                                   && root.game.collections.count > 0)
                                  ? root.game.collections.get(0).name.toUpperCase() : ""
                            color: Theme.alpha(Theme.textBright, 0.85)
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                            font.letterSpacing: 0.04 * 8
                        }
                    }
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    color: Theme.textBright
                    font.family: Theme.fontDisplay
                    font.bold: true
                    font.pixelSize: 14
                    lineHeight: 1.02
                    // El diseño las quiere en mayusculas (:151).
                    text: root.game ? root.game.title.toUpperCase() : ""
                }

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
                            color: root.activo ? root.accent
                                               : Theme.alpha(Theme.textBright, 0.5)
                        }
                    }
                }

                Rectangle {
                    visible: root.progreso >= 0
                    width: parent.width
                    height: 4
                    radius: 3
                    color: Theme.alpha(Theme.textBright, 0.18)

                    Rectangle {
                        // Piso de 4px: una barra de ancho cero no se ve, y
                        // "jugado muy poco" tiene que distinguirse de "no
                        // jugado" — que directamente no tiene barra.
                        width: Math.max(4, parent.width * Math.max(0, Math.min(1, root.progreso)))
                        height: parent.height
                        radius: parent.radius
                        color: root.accent

                        // El prototipo le pone glow (`box-shadow:0 0 8px
                        // {acc}`, Pegasus Home.dc.html:665). SIN glow a
                        // proposito: es una de N barras de 4px por tarjeta
                        // visible del rail, y ui/Sombra.qml ya dejo escrito
                        // por que un efecto de GPU no va por delegate — tantas
                        // pasadas como tarjetas visibles, en un rail que se
                        // mueve todo el tiempo. Mismo criterio, mismo motivo.
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
