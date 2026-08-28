// El overlay de galeria: imagenes y videos del juego a pantalla completa.
//
// NO ES EL VISOR DE DOCUMENTOS (DocumentViewer). Ese lee texto escaneado
// con zoom, paneo y progreso para cientos de paginas. Este muestra piezas
// multimedia de a una, con navegacion simple y wrap.
//
// Recibe la lista YA RESUELTA a URLs desde theme.qml. Ningun componente
// de overlays/ concatena rutas (mismo patron que CheatsOverlay).

import QtQuick 2.0
import QtMultimedia 5.9
import QtGraphicalEffects 1.0
import ".."
import "../ui"

FocusScope {
    id: root

    property var piezas: []             // [{ tipo, src, label }]
    property string titulo: ""
    property color accent: Theme.accentNeutro
    property Item fondo: null

    signal cerrar()

    anchors.fill: parent

    readonly property int total: piezas.length
    property int indice: 0

    readonly property var piezaActual:
        (indice >= 0 && indice < total) ? piezas[indice] : null

    // --- fondo -----------------------------------------------------------

    FastBlur {
        anchors.fill: parent
        source: root.fondo
        radius: 40
        visible: root.fondo !== null
        cached: true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(5/255, 6/255, 9/255, 0.86)
    }

    MouseArea {
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

            // Chip de tipo
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: tipoLabel.implicitWidth + 18
                height: 22
                radius: 5
                color: Theme.alpha(root.accent, 0.16)
                border.width: 1
                border.color: Theme.alpha(root.accent, 0.5)
                visible: root.piezaActual !== null

                Text {
                    id: tipoLabel
                    anchors.centerIn: parent
                    text: root.piezaActual && root.piezaActual.tipo === "vid" ? "VIDEO" : "IMAGEN"
                    color: root.accent
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.letterSpacing: 0.08 * 10
                }
            }

            // Label + titulo del juego
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                visible: root.piezaActual !== null

                Text {
                    text: root.piezaActual ? root.piezaActual.label : ""
                    color: Theme.textPrimary
                    font.family: Theme.fontDisplay
                    font.bold: true
                    font.pixelSize: 16
                }
                Text {
                    text: root.titulo
                    color: Theme.textFaint
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.letterSpacing: 0.08 * 10
                }
            }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 12

            // Contador
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.total > 0
                text: (root.indice + 1) + " / " + root.total
                color: Theme.textMuted
                font.family: Theme.fontMono
                font.pixelSize: Theme.sizeMono
            }

            Boton {
                anchors.verticalCenter: parent.verticalCenter
                texto: ""; glifo: "✕"; variant: "glass"; accent: root.accent
                implicitWidth: 32; implicitHeight: 30
                onActivado: root.cerrar()
            }
        }
    }

    // --- escenario -------------------------------------------------------

    Item {
        id: escenario
        anchors { top: barra.bottom; bottom: pie.top; left: parent.left; right: parent.right }
        anchors { topMargin: 12; bottomMargin: 12 }

        // --- pieza de imagen ---
        Image {
            id: imgPieza
            anchors.fill: parent
            anchors.margins: 60
            visible: root.piezaActual && root.piezaActual.tipo === "img" && root.piezaActual.src !== ""
            source: (root.piezaActual && root.piezaActual.tipo === "img") ? root.piezaActual.src : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            sourceSize.width: 1280
        }

        // --- pieza de video (Loader para ADR-0029: player nuevo por pieza) ---
        Loader {
            anchors.fill: parent
            anchors.margins: 60
            active: root.piezaActual && root.piezaActual.tipo === "vid" && root.piezaActual.src !== ""
            sourceComponent: Component {
                Item {
                    VideoOutput {
                        anchors.fill: parent
                        source: galleryPlayer
                        fillMode: VideoOutput.PreserveAspectFit
                    }
                    MediaPlayer {
                        id: galleryPlayer
                        source: root.piezaActual ? root.piezaActual.src : ""
                        autoPlay: true
                    }
                    // Controles basicos: play/pause y volumen
                    Row {
                        anchors { bottom: parent.bottom; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
                        spacing: 8
                        Boton {
                            texto: ""; glifo: galleryPlayer.playbackState === MediaPlayer.PlayingState ? "❚❚" : "▶"
                            variant: "glass"; accent: root.accent
                            implicitWidth: 30; implicitHeight: 30
                            onActivado: {
                                if (galleryPlayer.playbackState === MediaPlayer.PlayingState)
                                    galleryPlayer.pause();
                                else
                                    galleryPlayer.play();
                            }
                        }
                        Boton {
                            texto: ""; glifo: galleryPlayer.muted ? "🔇" : "🔊"
                            variant: "glass"; accent: root.accent
                            implicitWidth: 30; implicitHeight: 30
                            onActivado: galleryPlayer.muted = !galleryPlayer.muted
                        }
                    }
                }
            }
        }

        // --- placeholder para pieza sin archivo ---
        Rectangle {
            anchors.fill: parent
            anchors.margins: 60
            visible: root.piezaActual && root.piezaActual.src === ""
            color: "#141720"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.16)
            radius: 4

            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: root.piezaActual && root.piezaActual.src === ""

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.piezaActual ? "CAPTURA · " + root.piezaActual.label : ""
                    color: Theme.textPrimary
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "soltá acá la imagen real del juego"
                    color: Theme.textFaint
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                }
            }
        }

        // --- placeholder para imagen que no carga ---
        Column {
            anchors.centerIn: parent
            spacing: 8
            visible: root.piezaActual && root.piezaActual.tipo === "img"
                     && root.piezaActual.src !== "" && imgPieza.status === Image.Error

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.piezaActual ? "CAPTURA · " + root.piezaActual.label : ""
                color: Theme.textPrimary
                font.family: Theme.fontMono
                font.pixelSize: 14
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "imagen no disponible"
                color: Theme.textFaint
                font.family: Theme.fontMono
                font.pixelSize: 10
            }
        }

        // --- flechas de navegacion ---
        Boton {
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            visible: root.total > 1
            texto: ""; glifo: "‹"; variant: "glass"; accent: root.accent
            implicitWidth: 54; implicitHeight: 54
            onActivado: root.navegar(-1)
        }

        Boton {
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            visible: root.total > 1
            texto: ""; glifo: "›"; variant: "glass"; accent: root.accent
            implicitWidth: 54; implicitHeight: 54
            onActivado: root.navegar(1)
        }
    }

    // --- pie: miniaturas + leyenda ---------------------------------------

    Item {
        id: pie
        // Anclado a leyenda.top, como en DocumentViewer
        anchors { bottom: leyenda.top; left: parent.left; right: parent.right }
        anchors { bottomMargin: 10; leftMargin: Theme.gutter; rightMargin: Theme.gutter }
        height: 37

        ListView {
            id: tira
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            height: 37
            orientation: ListView.Horizontal
            spacing: 5
            model: root.total
            currentIndex: root.indice
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: 140
            clip: true

            delegate: Rectangle {
                width: 56; height: 37; radius: 3
                readonly property bool esActual: index === root.indice
                readonly property var pieza: root.piezas[index] || null
                readonly property bool tieneSrc: pieza && pieza.src !== ""

                color: esActual ? root.accent : Theme.glassFill
                border.width: esActual ? 2 : 1
                border.color: esActual ? root.accent : Theme.glassBorder

                // Miniatura de la pieza
                Image {
                    anchors.fill: parent
                    anchors.margins: 1
                    source: tieneSrc ? pieza.src : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                    asynchronous: true
                    sourceSize.width: 112
                    opacity: esActual ? 1 : 0.6
                }

                // Indicador de play para video
                Rectangle {
                    anchors.centerIn: parent
                    width: 20; height: 20; radius: 10
                    visible: pieza && pieza.tipo === "vid" && !tieneSrc
                    color: Qt.rgba(4/255, 5/255, 9/255, 0.6)
                    Text {
                        anchors.centerIn: parent
                        text: "▶"
                        color: Theme.textPrimary
                        font.pixelSize: 10
                    }
                }

                // Placeholder para pieza sin archivo
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    visible: !tieneSrc
                    color: "#1a1d28"
                    radius: 2
                    Text {
                        anchors.centerIn: parent
                        text: index + 1
                        color: Theme.textFaint
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.irA(index)
                }
            }
        }
    }

    Text {
        id: leyenda
        // Anclada al borde REAL de la pantalla, como en DocumentViewer
        height: 14
        verticalAlignment: Text.AlignVCenter
        anchors { bottom: parent.bottom; bottomMargin: 14; horizontalCenter: parent.horizontalCenter }
        color: Theme.textFaint
        font.family: Theme.fontMono
        font.pixelSize: 7
        font.letterSpacing: Theme.trackingLabel * 7
        text: "◄ ► Imagen / video   B / Esc Cerrar"

        SequentialAnimation on opacity {
            running: root.visible
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 900 }
            NumberAnimation { to: 1.0; duration: 900 }
        }
    }

    // --- acciones --------------------------------------------------------

    function navegar(delta) {
        if (total <= 0) return;
        indice = (indice + delta + total) % total;
    }

    function irA(i) {
        if (i < 0 || i >= total) return;
        indice = i;
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            root.cerrar();
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            root.navegar(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.navegar(-1);
            event.accepted = true;
        }
    }
}
