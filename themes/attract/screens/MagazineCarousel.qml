// El carrusel "NOTAS EN REVISTAS" de la columna izquierda del detalle: las
// tapas de las revistas que cubren a este juego, dos visibles a la vez.
//
// NO SE DIBUJAN TAPAS FALSAS. El prototipo, cuando no tenia el escaneo,
// inventaba una tapa entera con cabecera, nota y codigo de barras dibujados en
// CSS. Nosotros no: una revista cuya tapa no carga se muestra como lo que es.
// El handoff mismo dice que ningun placeholder llega a produccion, y una tapa
// inventada es peor que un hueco honesto — miente sobre que hay escaneado.
//
// El bloque NUNCA desaparece: sin revistas dice "Sin cobertura en revistas"
// (CONVENCION #2.3, que le gana al handoff en esto).
//
// Cada tapa trae su propio MagazineData. Un juego tiene pocas revistas, asi
// que un Row + Repeater alcanza — no hace falta el reciclado de un ListView. Y
// el cache es compartido (core/DataCache.js), que acá importa de verdad: la
// MISMA revista cubre varios juegos.

import QtQuick 2.0
import ".."
import "../core"
import "../ui"

Item {
    id: root

    property var game: null
    property var paths: null
    property var mags: []               // data.json -> mags: [{ref}]
    property color accent: Theme.accentNeutro
    property bool activo: false

    // Primera tapa visible. El diseno muestra dos y desliza de a una.
    property int indice: 0

    signal abrir(int i)

    readonly property int total: mags.length
    readonly property int _maxIndice: Math.max(0, total - 2)
    readonly property bool hay: total > 0

    implicitHeight: etiqueta.height + 10 + 178 + 10 + pie.height

    SectionLabel {
        id: etiqueta
        text: "NOTAS EN REVISTAS"
        activo: root.activo
        accent: root.accent
    }

    // --- sin revistas: el bloque se queda, con su mensaje ---
    Text {
        anchors { top: etiqueta.bottom; topMargin: 14; left: parent.left }
        visible: !root.hay
        text: "Sin cobertura en revistas"
        color: Theme.textFaint
        font.family: Theme.fontBody
        font.pixelSize: Theme.sizeLabel
    }

    // --- el viewport: dos tapas a la vez ---
    Item {
        id: viewport
        anchors { top: etiqueta.bottom; topMargin: 10; left: parent.left; right: parent.right }
        height: 178
        clip: true
        visible: root.hay

        Row {
            id: pista
            spacing: 10
            height: parent.height
            // 133 de tapa + 10 de gap = 143 por paso, como el diseno.
            x: -root.indice * 143
            Behavior on x {
                NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
            }

            Repeater {
                model: root.mags

                Item {
                    width: 133
                    height: 178

                    readonly property bool enfocada:
                        root.activo && index === root.indice

                    MagazineData {
                        id: revista
                        game: root.game
                        paths: root.paths
                        ref: modelData.ref ? modelData.ref : ""
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.panelTop
                        border.width: 1
                        border.color: Theme.glassBorder
                    }

                    Image {
                        id: tapa
                        anchors.fill: parent
                        anchors.margins: 1
                        source: revista.urlTapa
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 266        // 2x, para que no se vea blanda
                        visible: status === Image.Ready
                    }

                    // Lo que se ve cuando la tapa no esta: el estado real, no
                    // una tapa inventada. El `ref` colgado de sf2ce es el
                    // fixture de este caso.
                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 20
                        spacing: 6
                        visible: !tapa.visible

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: revista.estado === "cargando" ? "…"
                                  : (revista.estado === "sin-datos"
                                     ? "Revista no disponible" : "Sin tapa")
                            color: Theme.textFaint
                            font.family: Theme.fontBody
                            font.pixelSize: 11
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            // Con el ref colgado no hay ni nombre: se muestra
                            // el ref, que es lo unico que sabemos de ella.
                            text: revista.displayName !== "" ? revista.displayName
                                                             : (modelData.ref || "")
                            color: Theme.textMuted
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                        }
                    }

                    // Cabecera con el color de marca de la revista. `color` es
                    // opcional en el contrato (ADR-0010): sin el, el accent.
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        anchors.margins: 1
                        height: 26
                        visible: tapa.visible
                        color: Theme.alpha(revista.colorMarca !== ""
                                           ? revista.colorMarca : root.accent, 0.92)

                        Text {
                            anchors.fill: parent
                            anchors.margins: 5
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            text: revista.displayName
                            color: Theme.textBright
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                        }
                    }

                    FocusRing {
                        accent: root.accent
                        activo: parent.enfocada
                        radio: 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.indice = Math.min(root._maxIndice, index);
                            root.abrir(index);
                        }
                    }
                }
            }
        }
    }

    // --- flechas: solo con mas de dos revistas ---
    Boton {
        anchors { left: viewport.left; leftMargin: 4; verticalCenter: viewport.verticalCenter }
        visible: root.total > 2
        texto: ""
        glifo: "‹"
        variant: "glass"
        accent: root.accent
        implicitWidth: 30
        implicitHeight: 30
        opacity: root.indice > 0 ? 1 : 0.3
        onActivado: root.pasar(-1)
    }

    Boton {
        anchors { right: viewport.right; rightMargin: 4; verticalCenter: viewport.verticalCenter }
        visible: root.total > 2
        texto: ""
        glifo: "›"
        variant: "glass"
        accent: root.accent
        implicitWidth: 30
        implicitHeight: 30
        opacity: root.indice < root._maxIndice ? 1 : 0.3
        onActivado: root.pasar(1)
    }

    // --- puntos y contador ---
    Item {
        id: pie
        anchors { top: viewport.bottom; topMargin: 10; left: parent.left; right: parent.right }
        height: 14
        visible: root.hay

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5
            Repeater {
                model: root.total
                Rectangle {
                    // El punto de las visibles es una pastilla ancha; el resto,
                    // un punto. Se lee de un vistazo cuantas hay y donde estas.
                    readonly property bool visibleAhora:
                        index >= root.indice && index < root.indice + 2
                    width: visibleAhora ? 16 : 6
                    height: 6
                    radius: 3
                    color: visibleAhora ? root.accent : Theme.alpha(Theme.textBright, 0.25)
                    Behavior on width { NumberAnimation { duration: 250 } }
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
            }
        }

        Text {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            color: Theme.textFaint
            font.family: Theme.fontMono
            font.pixelSize: Theme.sizeMonoSm
            text: {
                if (!root.hay) return "";
                var hasta = Math.min(root.total, root.indice + 2);
                var desde = root.indice + 1;
                return (hasta > desde ? desde + "–" + hasta : String(desde))
                       + " / " + root.total;
            }
        }
    }

    // --- teclas -----------------------------------------------------------

    function pasar(d) {
        indice = Math.max(0, Math.min(_maxIndice, indice + d));
    }

    // Devuelve true si consumio la tecla. Arriba/abajo pasan de pagina
    // MIENTRAS el carrusel tiene el foco — la regla del detalle: horizontal
    // mueve entre targets, vertical actua dentro del target enfocado.
    function manejarTecla(event) {
        if (!activo || !hay) return false;

        if (event.key === Qt.Key_Down) { pasar(1); return true; }
        if (event.key === Qt.Key_Up) { pasar(-1); return true; }
        if (api.keys.isAccept(event)) { root.abrir(indice); return true; }
        return false;
    }
}
