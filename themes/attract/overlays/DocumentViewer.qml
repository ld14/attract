// El visor de documentos paginado. Lo comparten las revistas y el manual.
//
// NO SABE cual de los dos le tocó: recibe un modelo armado por core/DocModel
// y dibuja paginas. Toda la diferencia entre una revista y un manual vive en
// como se arma ese modelo. Esa es la razon por la que ADR-0014 le dio a
// manual.pages[] la misma forma que a magazine.json -> pages[]; acá se cobra.
//
// LO QUE HACE QUE ESTO VALGA LA PENA, y que el prototipo no podia hacer porque
// no tenia el concepto de articulo: se entra DIRECTO a la nota del juego, pero
// el modelo son TODAS las paginas de la revista. La nota es la puerta de
// entrada, no un limite (docs/decisiones/2026-07-23.md #5). Las paginas del
// articulo se marcan en la tira de miniaturas — sale gratis del contrato y es
// la unica pista visual de por que el visor abrio donde abrio.
//
// NO SE DIBUJAN PAGINAS FALSAS. El prototipo generaba reseñas en papel
// pergamino y diagramas de control en CSS porque no tenia escaneos. Nosotros
// si; una pagina que no carga se muestra como lo que es.

import QtQuick 2.0
import QtGraphicalEffects 1.0
import ".."
import "../ui"

FocusScope {
    id: root

    // El objeto plano que devuelven DocModel.desdeRevista / .desdeManual
    property var modelo: null
    property color accent: Theme.accentNeutro

    // Lo que se ve detras, para el desenfoque. Si no se pasa, queda el scrim
    // solo — el visor funciona igual.
    property Item fondo: null

    // Pestañas: las revistas del juego, para cambiar sin salir del visor.
    property var revistas: []           // [{etiqueta, color}]
    property int revistaActual: 0

    signal cerrar()
    signal cambiarRevista(int i)

    anchors.fill: parent

    readonly property int total: modelo ? modelo.paginas.length : 0
    property int pagina: 0

    // Los 4 pasos del diseno.
    readonly property var _zooms: [1.0, 1.4, 1.85, 2.4]
    property int zoomIdx: 0
    readonly property real zoom: _zooms[zoomIdx]

    property real panY: 0

    onModeloChanged: {
        pagina = modelo ? Math.max(0, Math.min(total - 1, modelo.inicio)) : 0;
        zoomIdx = 0;
        panY = 0;
    }

    // --- fondo -----------------------------------------------------------

    FastBlur {
        anchors.fill: parent
        source: root.fondo
        radius: 40                  // el "backdrop-filter: blur(16px)" del CSS
        visible: root.fondo !== null
        cached: true                // lo de atras esta quieto: se calcula una vez
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(5/255, 6/255, 9/255, 0.86)
    }

    MouseArea {                     // traga los clicks que no son del visor
        anchors.fill: parent
        onClicked: root.cerrar()
    }

    // --- barra superior --------------------------------------------------

    Item {
        id: barra
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors { topMargin: 22; leftMargin: Theme.gutter; rightMargin: Theme.gutter }
        height: 34

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (root.modelo && root.modelo.tipo === "manual") ? "❐" : "▤"
                color: root.accent
                font.pixelSize: 16
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.modelo ? root.modelo.titulo : ""
                color: Theme.textPrimary
                font.family: Theme.fontDisplay
                font.bold: true
                font.pixelSize: 16
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: text !== ""
                text: root.modelo ? root.modelo.fuente : ""
                color: Theme.textFaint
                font.family: Theme.fontMono
                font.pixelSize: Theme.sizeMono
            }
        }

        // Pestañas: solo tienen sentido con mas de una revista.
        Row {
            anchors { right: cerrarBtn.left; rightMargin: 14; verticalCenter: parent.verticalCenter }
            spacing: 8
            visible: root.revistas.length > 1

            Repeater {
                model: root.revistas
                Rectangle {
                    readonly property bool sel: index === root.revistaActual
                    width: fila.width + 22
                    height: 28
                    radius: 7
                    color: sel ? root.accent : Theme.glassFill
                    border.width: sel ? 0 : 1
                    border.color: Theme.glassBorder

                    Row {
                        id: fila
                        anchors.centerIn: parent
                        spacing: 8
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8; height: 8; radius: 2
                            color: modelData.color !== "" ? modelData.color
                                                          : Theme.textBright
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.etiqueta
                            color: sel ? Theme.textOnAccent : Theme.textBody
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.cambiarRevista(index)
                    }
                }
            }
        }

        Boton {
            id: cerrarBtn
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            texto: ""
            glifo: "✕"
            variant: "glass"
            accent: root.accent
            implicitWidth: 34
            implicitHeight: 30
            onActivado: root.cerrar()
        }
    }

    // --- la hoja ---------------------------------------------------------

    Item {
        id: escenario
        anchors { top: barra.bottom; bottom: pie.top; left: parent.left; right: parent.right }
        anchors { topMargin: 12; bottomMargin: 12 }
        clip: true

        readonly property int anchoHoja:
            (root.modelo && root.modelo.tipo === "manual") ? 540 : 560

        Item {
            id: hoja
            width: escenario.anchoHoja
            height: Math.min(760, escenario.height)
            anchors.centerIn: parent

            scale: root.zoom
            transform: Translate { y: root.panY }
            Behavior on scale { NumberAnimation { duration: 120 } }
            Behavior on y { NumberAnimation { duration: 120 } }

            Rectangle {
                anchors.fill: parent
                color: "#ece2cf"          // el mat de papel del diseno
            }

            Image {
                id: pagActual
                anchors.fill: parent
                source: root.modelo ? root.modelo.paginas[root.pagina] || "" : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                // El zoom pide MAS resolucion, no la misma imagen estirada.
                sourceSize.width: Math.round(escenario.anchoHoja * root.zoom * 1.2)
                visible: status === Image.Ready
            }

            // Una pagina que no carga se muestra como lo que es. Sin inventar
            // una pagina de revista falsa como hacia el prototipo.
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: !pagActual.visible

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: pagActual.status === Image.Loading ? "…" : "Página no disponible"
                    color: "#8a7f6a"
                    font.family: Theme.fontBody
                    font.pixelSize: 15
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: (root.pagina + 1) + " / " + root.total
                    color: "#a2977f"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
            }
        }

        // Precarga de +-1. Ni todas ni ninguna: al pasar de pagina la
        // siguiente ya esta decodificada y el salto no parpadea.
        Image {
            visible: false
            asynchronous: true
            sourceSize.width: escenario.anchoHoja
            source: (root.modelo && root.pagina + 1 < root.total)
                    ? root.modelo.paginas[root.pagina + 1] : ""
        }
        Image {
            visible: false
            asynchronous: true
            sourceSize.width: escenario.anchoHoja
            source: (root.modelo && root.pagina > 0)
                    ? root.modelo.paginas[root.pagina - 1] : ""
        }

        Boton {
            anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
            texto: ""; glifo: "‹"; variant: "glass"; accent: root.accent
            implicitWidth: 54; implicitHeight: 54
            opacity: root.pagina > 0 ? 1 : 0.3
            onActivado: root.irA(root.pagina - 1)
        }

        Boton {
            anchors { right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
            texto: ""; glifo: "›"; variant: "glass"; accent: root.accent
            implicitWidth: 54; implicitHeight: 54
            opacity: root.pagina < root.total - 1 ? 1 : 0.3
            onActivado: root.irA(root.pagina + 1)
        }
    }

    // --- pie: miniaturas, contador y zoom --------------------------------

    Item {
        id: pie
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        anchors { bottomMargin: 20; leftMargin: Theme.gutter; rightMargin: Theme.gutter }
        height: 46

        ListView {
            id: tira
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: parent.width - 260
            height: 46
            orientation: ListView.Horizontal
            spacing: 6
            model: root.total
            currentIndex: root.pagina
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: 140
            clip: true

            delegate: Rectangle {
                width: 34; height: 46; radius: 4
                readonly property bool esActual: index === root.pagina
                // Las paginas del articulo del juego, marcadas. Es la unica
                // pista de por que el visor abrio donde abrio.
                readonly property bool destacada:
                    root.modelo && root.modelo.destacadas.indexOf(index) >= 0

                color: esActual ? root.accent : Theme.glassFill
                border.width: 1
                border.color: esActual ? root.accent
                              : (destacada ? Theme.alpha(root.accent, 0.55)
                                           : Theme.glassBorder)

                Text {
                    anchors.centerIn: parent
                    text: index + 1
                    color: esActual ? Theme.textOnAccent
                           : (destacada ? root.accent : Theme.textMuted)
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.bold: parent.destacada
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.irA(index)
                }
            }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "PÁG. " + (root.pagina + 1) + " / " + root.total
                color: Theme.textMuted
                font.family: Theme.fontMono
                font.pixelSize: Theme.sizeMono
            }

            Boton {
                texto: ""; glifo: "−"; variant: "glass"; accent: root.accent
                implicitWidth: 30; implicitHeight: 30
                onActivado: root.zoomear(-1)
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                horizontalAlignment: Text.AlignHCenter
                text: Math.round(root.zoom * 100) + "%"
                color: Theme.textBody
                font.family: Theme.fontMono
                font.pixelSize: Theme.sizeMono
            }

            Boton {
                texto: ""; glifo: "+"; variant: "glass"; accent: root.accent
                implicitWidth: 30; implicitHeight: 30
                onActivado: root.zoomear(1)
            }
        }
    }

    Text {
        anchors { bottom: pie.top; bottomMargin: 4; horizontalCenter: parent.horizontalCenter }
        color: Theme.textFaint
        font.family: Theme.fontMono
        font.pixelSize: Theme.sizeMonoSm
        font.letterSpacing: Theme.trackingLabel * Theme.sizeMonoSm
        text: root.zoom > 1 ? "◄ ► PÁGINA   ▲ ▼ MOVER   + − ZOOM   B CERRAR"
                            : "◄ ► PÁGINA   + − ZOOM   B CERRAR"
    }

    // --- acciones ---------------------------------------------------------

    function irA(i) {
        if (i < 0 || i >= total) return;
        pagina = i;
        panY = 0;          // cambiar de pagina recentra: quedar perdido a mitad
                           // de la hoja anterior desorienta
    }

    function zoomear(d) {
        var n = Math.max(0, Math.min(_zooms.length - 1, zoomIdx + d));
        if (n === zoomIdx) return;
        zoomIdx = n;
        if (zoom <= 1) panY = 0;
        else limitarPan();
    }

    function limitarPan() {
        // Cuanto sobresale la hoja del escenario, de cada lado.
        var sobra = Math.max(0, (hoja.height * zoom - escenario.height) / 2);
        panY = Math.max(-sobra, Math.min(sobra, panY));
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            root.cerrar(); event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            root.irA(root.pagina + 1); event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.irA(root.pagina - 1); event.accepted = true;
        } else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
            root.zoomear(1); event.accepted = true;
        } else if (event.key === Qt.Key_Minus) {
            root.zoomear(-1); event.accepted = true;
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
            // Paneo con D-pad, que el handoff solo habia resuelto con mouse.
            // SOLO vertical: a 2.4x una hoja de 560 mide 1344 sobre un lienzo
            // de 1280, o sea que horizontalmente casi no sobra nada. Lo que se
            // sale de pantalla es el alto (760 -> 1824). Un paneo horizontal
            // seria un control que no mueve nada.
            if (root.zoom > 1) {
                root.panY += (event.key === Qt.Key_Down ? -60 : 60);
                root.limitarPan();
                event.accepted = true;
            }
        }
    }
}
