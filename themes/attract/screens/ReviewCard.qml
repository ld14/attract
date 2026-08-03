// El bloque NOTA DE LA CRITICA: un scorecard con estetica de revista de la
// epoca. Marco con esquinas en accent, banda de encabezado, seis categorias
// con barra, veredicto y el puntaje grande abajo.
//
// LOS DOS NIVELES DE "SIN DATO" DE CONVENCION #2.3 VIVEN ACA:
//
//   sin review          -> el bloque NO desaparece: se muestra entero con
//                          "Sin Informacion". Es la divergencia consciente
//                          respecto del handoff, que pedia omitirlo.
//   review parcial      -> se muestra lo que hay; cada categoria sin dato
//                          va con "-" y su barra vacia, las demas normales.
//
// El bloque NUNCA lee el `rating` nativo de Pegasus para decidir si hay nota:
// ese campo no distingue "sin nota" de "nota cero" (su default es 0.0). Lee
// `review` de data.json, que si puede ser null de verdad. Decidido en el
// LAB 0.3, ver docs/mapeo-mockup-pegasus.md y CONVENCION #2.3.

import QtQuick 2.0
import ".."
import "../ui"

Item {
    id: root

    property var datos: null            // el GameData de la pantalla
    property color accent: Theme.accentNeutro

    // Las seis de CONVENCION #2.1 nota 3. La clave es como viene en el JSON
    // (minuscula, sin tildes); la etiqueta la pone el theme, no los datos.
    readonly property var _cats: [
        ["originalidad", "ORIGINALIDAD"],
        ["graficos",     "GRÁFICOS"],
        ["adiccion",     "ADICCIÓN"],
        ["sonido",       "SONIDO"],
        ["dificultad",   "DIFICULTAD"],
        ["animacion",    "ANIMACIÓN"]
    ]

    readonly property bool hay: datos && datos.hayReview

    implicitHeight: columna.height

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: Theme.alpha(Theme.panelTop, 0.85)
        border.width: 1
        border.color: Theme.alpha(root.accent, root.hay ? 0.45 : 0.15)
    }

    // Scanlines: la textura de papel impreso del diseno. Se pinta una vez.
    Canvas {
        anchors.fill: parent
        opacity: 0.10
        renderStrategy: Canvas.Cooperative
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.5);
            for (var y = 0; y < height; y += 3) ctx.fillRect(0, y, width, 1);
        }
    }

    Column {
        id: columna
        width: parent.width
        spacing: 0

        // banda de encabezado
        Rectangle {
            width: parent.width
            height: 26
            color: Theme.alpha(root.accent, root.hay ? 0.18 : 0.07)

            Text {
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                text: "NOTA DE LA CRÍTICA"
                color: root.hay ? root.accent : Theme.textFaint
                font.family: Theme.fontMono
                font.pixelSize: 9
                font.letterSpacing: Theme.trackingLabel * 9
            }
        }

        Item { width: 1; height: 10 }

        // --- sin reseña: el bloque se queda, con su mensaje ---
        Item {
            width: parent.width
            height: root.hay ? 0 : 54
            visible: !root.hay

            Text {
                anchors.centerIn: parent
                text: "Sin Información"
                color: Theme.textFaint
                font.family: Theme.fontBody
                font.pixelSize: Theme.sizeLabel
            }
        }

        // --- las seis categorias ---
        Column {
            width: parent.width - 20
            x: 10
            spacing: 6
            visible: root.hay

            Repeater {
                model: root._cats

                Item {
                    width: parent.width
                    height: 15

                    // null = esta categoria puntual no tiene dato cargado.
                    // Pasa en la practica: resenas parciales.
                    property var valor: root.datos ? root.datos.catDe(modelData[0]) : null

                    Text {
                        anchors.left: parent.left
                        width: 82
                        text: modelData[1]
                        color: Theme.textMuted
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        font.letterSpacing: 0.06 * 8
                    }

                    Text {
                        anchors.right: parent.right
                        width: 20
                        horizontalAlignment: Text.AlignRight
                        text: parent.valor === null ? "-" : String(parent.valor)
                        color: parent.valor === null ? Theme.textFaint : Theme.textPrimary
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                    }

                    Rectangle {
                        anchors { left: parent.left; leftMargin: 86; right: parent.right; rightMargin: 24 }
                        anchors.verticalCenter: parent.verticalCenter
                        height: 5
                        radius: 2.5
                        color: Theme.alpha(Theme.textBright, 0.08)

                        Rectangle {
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                            width: parent.width * ((parent.parent.valor || 0) / 100)
                            radius: 2.5
                            color: root.accent
                            Behavior on width { NumberAnimation { duration: 250 } }
                        }
                    }
                }
            }
        }

        Item { width: 1; height: 10; visible: root.hay }

        // --- veredicto ---
        Text {
            x: 10
            width: parent.width - 20
            wrapMode: Text.WordWrap
            visible: root.hay && text !== ""
            color: Theme.textBody
            font.family: Theme.fontBody
            font.pixelSize: 10
            lineHeight: 1.4
            text: (root.datos && root.datos.review && root.datos.review.verdict)
                  ? root.datos.review.verdict : ""
        }

        Item { width: 1; height: 10 }

        // --- el puntaje grande ---
        Rectangle {
            width: parent.width
            height: 52
            color: Theme.alpha(root.accent, root.hay ? 0.12 : 0.05)

            Row {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (!root.hay) return "--";
                        var s = root.datos.review.score;
                        return (typeof s === "number") ? String(s) : "--";
                    }
                    color: root.hay ? root.accent : Theme.textFaint
                    font.family: Theme.fontDisplay
                    font.bold: true
                    font.pixelSize: 34
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "PUNTUACIÓN\nSOBRE 100"
                    color: Theme.textFaint
                    font.family: Theme.fontMono
                    font.pixelSize: 7
                    font.letterSpacing: 0.1 * 7
                    lineHeight: 1.3
                }
            }
        }
    }

    // Las esquinas en accent del diseno, estilo HUD. Cuatro escuadras, no un
    // borde entero.
    Repeater {
        model: [[0, 0], [1, 0], [0, 1], [1, 1]]
        Item {
            width: 12; height: 12
            x: modelData[0] === 0 ? -1 : root.width - 11
            y: modelData[1] === 0 ? -1 : root.height - 11
            Rectangle {
                width: 12; height: 2
                anchors.top: modelData[1] === 0 ? parent.top : undefined
                anchors.bottom: modelData[1] === 1 ? parent.bottom : undefined
                anchors.left: modelData[0] === 0 ? parent.left : undefined
                anchors.right: modelData[0] === 1 ? parent.right : undefined
                color: Theme.alpha(root.accent, root.hay ? 0.9 : 0.3)
            }
            Rectangle {
                width: 2; height: 12
                anchors.top: modelData[1] === 0 ? parent.top : undefined
                anchors.bottom: modelData[1] === 1 ? parent.bottom : undefined
                anchors.left: modelData[0] === 0 ? parent.left : undefined
                anchors.right: modelData[0] === 1 ? parent.right : undefined
                color: Theme.alpha(root.accent, root.hay ? 0.9 : 0.3)
            }
        }
    }
}
