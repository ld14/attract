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

    // Pestañas: varios documentos del mismo tipo, para cambiar sin salir del
    // visor. Las usan las revistas (varias por juego, feature 006) Y el
    // manual cuando hay mas de uno (ADR-0023) — nunca las dos filas a la vez,
    // asi que un solo prop alcanza. `color` es "" cuando no aplica (manual).
    property var pestanas: []           // [{etiqueta, color}]
    property int pestanaActual: 0

    signal cerrar()
    signal cambiarPestana(int i)

    // El manual puede traer ademas un PDF (ADR-0021). El visor NO lo abre: no
    // sabe hablar con el sistema operativo y no es su trabajo. Avisa hacia
    // arriba con la url ya resuelta y sigue con lo suyo.
    signal abrirPdf(string url)

    readonly property string pdf: (modelo && modelo.pdf) ? modelo.pdf : ""
    readonly property bool hayPdf: pdf !== ""

    anchors.fill: parent

    readonly property int total: modelo ? modelo.paginas.length : 0
    property int pagina: 0

    // A partir de cuantas paginas la tira de miniaturas deja de alcanzar por
    // si sola: con 26 (Golden Axe) ya raspa el ancho del pie; mas alla de esto
    // hace falta saber CUANTO falta, no solo scrollear a ciegas. El numero es
    // deliberadamente mas bajo que "cuando ya se rompe": la barra ayuda antes
    // de que haga falta, no cuando ya es tarde.
    readonly property int _umbralDocumentoLargo: 40

    // Salto grande: L2/R2 del gamepad (isPageUp/isPageDown, medidos y sin usar
    // contra este binario hasta ahora — ver themes/experimentos/teclas-xy.qml
    // #RESULTADO OBSERVADO). Es la unica forma de moverse por un documento de
    // 100+ paginas sin scrollear la tira entera pagina a pagina.
    readonly property int _saltoGrande: 10

    // Los 4 pasos del diseno, mas dos que el diseno no tenia porque no tenia
    // escaneos de verdad. Medido contra una pagina real de micromania-34
    // (p046.jpg, 1682x2152 nativos, que entra en la hoja como 446x570):
    //
    //   zoom    en pantalla   sobra X   sobra Y   % de la resolucion nativa
    //   1.0      446x570           0         0     26%
    //   2.4     1069x1368          0       399     64%   <- el maximo de antes
    //   3.2     1426x1824         73       627     85%
    //   4.0     1782x2280        251       855    106%
    //
    // Los dos pasos nuevos no son "mas zoom por las dudas": a 2.4x se estaba
    // mostrando el 64% del detalle que el escaneo YA tiene, y el texto de la
    // nota no se llega a leer. La escala termina en 4.0 porque ahi se pasa la
    // resolucion nativa — de ahi para arriba es agrandar pixeles.
    //
    // Es tambien lo unico que hace que el paneo horizontal exista: hasta 2.4x
    // la hoja entra entera a lo ancho (sobra X = 0) y arrastrar de costado no
    // movia nada. Un control que no mueve nada es el mismo error que una
    // leyenda que nombra una tecla muerta (ui/Leyenda.qml).
    readonly property var _zooms: [1.0, 1.4, 1.85, 2.4, 3.2, 4.0]
    property int zoomIdx: 0
    readonly property real zoom: _zooms[zoomIdx]

    property real panX: 0
    property real panY: 0

    // Si en el zoom actual sobra algo para arrastrar, y en que eje. Lo usa el
    // cursor y el arrastre para no fingir que se puede mover lo que no.
    readonly property bool puedePanearX: _sobraX > 0
    readonly property bool puedePanearY: _sobraY > 0
    readonly property bool puedePanear: puedePanearX || puedePanearY

    onModeloChanged: {
        pagina = modelo ? Math.max(0, Math.min(total - 1, modelo.inicio)) : 0;
        zoomIdx = 0;
        panX = 0;
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

        // Pestañas: solo tienen sentido con mas de un documento.
        Row {
            anchors { right: cerrarBtn.left; rightMargin: 14; verticalCenter: parent.verticalCenter }
            spacing: 8
            visible: root.pestanas.length > 1

            Repeater {
                model: root.pestanas
                Rectangle {
                    readonly property bool sel: index === root.pestanaActual
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
                            // El manual no tiene color propio (ADR-0023): el
                            // indicador cae al neutro, igual que una revista
                            // sin color declarado.
                            color: (modelData.color && modelData.color !== "") ? modelData.color
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
                        onClicked: root.cambiarPestana(index)
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
            // Qt aplica el `transform` DESPUES del scale (la escala es lo mas
            // interno de la matriz), asi que panX/panY estan en pixeles de
            // pantalla, no de la hoja. Por eso limitarPan() puede comparar
            // contra el tamaño del escenario directamente, y por eso el delta
            // del arrastre del mouse entra 1:1 sin dividir por el zoom.
            transform: Translate { x: root.panX; y: root.panY }
            Behavior on scale { NumberAnimation { duration: 120 } }

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

        // Arrastrar la hoja con el mouse. Vive en `escenario` y NO en `hoja`
        // a proposito: `hoja` esta escalada, asi que ahi los deltas del mouse
        // vendrian multiplicados por el zoom y el arrastre se sentiria mas
        // rapido cuanto mas cerca estas — justo al reves de lo que se espera.
        //
        // Va declarado ANTES de los botones ‹ › para que ellos queden encima:
        // en QML gana el ultimo hermano.
        //
        // Solo el mouse. En el gabinete no hay (roadmap, feature 007), y el
        // D-pad ya panea en vertical mas abajo; horizontal por teclado no se
        // agrega porque ◄ ► son pasar de pagina, y hacer que cambien de
        // significado segun el zoom es una sorpresa, no un atajo.
        MouseArea {
            id: arrastre
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: !root.puedePanear ? Qt.ArrowCursor
                         : (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)

            property real _x0: 0
            property real _y0: 0
            property real _panX0: 0
            property real _panY0: 0
            // Si este gesto ya se paso del umbral. Distingue "click" de
            // "arrastre" para no cerrar el visor al soltar despues de mover.
            property bool _movio: false

            onPressed: {
                _x0 = mouse.x; _y0 = mouse.y;
                _panX0 = root.panX; _panY0 = root.panY;
                _movio = false;
            }

            onPositionChanged: {
                if (!root.puedePanear) return;
                var dx = mouse.x - _x0;
                var dy = mouse.y - _y0;
                // Umbral: un click nunca es perfectamente quieto, y sin esto
                // temblar 1px al soltar ya contaria como arrastre y el click
                // para cerrar dejaria de funcionar.
                if (!_movio && Math.abs(dx) + Math.abs(dy) < 4) return;
                _movio = true;
                root.panX = _panX0 + dx;
                root.panY = _panY0 + dy;
                root.limitarPan();
            }

            // Sin arrastre, el click cierra: es el comportamiento que ya tenia
            // el visor antes de que esta MouseArea existiera, y taparlo sin
            // querer seria una regresion silenciosa.
            onClicked: if (!_movio) root.cerrar()
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

    // --- pie: barra de progreso (documentos largos), miniaturas, contador y
    //     zoom -----------------------------------------------------------

    Item {
        id: pie
        // El bottom es `leyenda.top`, no `parent.bottom`: la leyenda vive
        // DEBAJO de la tira de miniaturas y los controles (pedido explicito,
        // 2026-08-09) — antes flotaba arriba del pie y quedaba superpuesta a
        // las tarjetas desenfocadas del detalle, detras del visor.
        anchors { bottom: leyenda.top; left: parent.left; right: parent.right }
        anchors { bottomMargin: 10; leftMargin: Theme.gutter; rightMargin: Theme.gutter }
        // Crece 11px cuando la barra de progreso esta presente (14 de origen,
        // -20%). La tira y `controles` se anclan entre si (ver mas abajo), no
        // a `parent`, asi que este alto extra no los desalinea.
        height: barraProgreso.visible ? 37 + 11 : 37

        // SOLO para documentos largos (> _umbralDocumentoLargo). La tira de
        // miniaturas ya dice "donde estoy" con precision para un puñado de
        // paginas; en cientos de paginas esa precision no ayuda y lo que hace
        // falta es la posicion RELATIVA de un vistazo, sin escanear numeros.
        // No aparece nunca para sf2ce/dino (4/26 paginas): agregarla siempre
        // seria decorar sin necesidad.
        Item {
            id: barraProgreso
            visible: root.total > root._umbralDocumentoLargo
            anchors { top: parent.top; left: parent.left; right: controles.left; rightMargin: 16 }
            height: visible ? 11 : 0

            Rectangle {                       // el track
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                height: 3
                radius: 1.5
                color: Theme.glassFill
                border.width: 1
                border.color: Theme.glassBorder
            }

            Rectangle {                       // el relleno, hasta la pagina actual
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                height: 3
                radius: 1.5
                width: root.total > 0 ? parent.width * (root.pagina + 1) / root.total : 0
                color: root.accent
                Behavior on width { NumberAnimation { duration: 120 } }
            }
        }

        ListView {
            id: tira
            // El ancho se calcula contra `controles`, NO un numero fijo: con
            // el boton PDF visible (X ABRIR PDF, feature 012) el bloque de la
            // derecha es mas ancho que sin el, y un "260" a mano quedaba corto
            // -la tira se superponia con el contador ("22" pisado por
            // "PÁG. 21/26", visto en Pegasus real 2026-08-09). Anclando al
            // borde real de `controles` esto no puede volver a desalinearse
            // aunque el Row de la derecha crezca o encoja.
            anchors { left: parent.left; right: controles.left; rightMargin: 16 }
            anchors.bottom: parent.bottom
            height: 37
            orientation: ListView.Horizontal
            spacing: 5
            model: root.total
            currentIndex: root.pagina
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: 140
            clip: true

            delegate: Rectangle {
                // -20% respecto al tamaño original (34x46, radius 4).
                width: 27; height: 37; radius: 3
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
                    // 9, no el 8 que daria el -20% exacto: por debajo de eso
                    // el numero deja de leerse limpio en mono.
                    font.pixelSize: 9
                    font.bold: parent.destacada
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.irA(index)
                }
            }
        }

        Row {
            id: controles
            // Alineado con la TIRA, no con `pie` entero: cuando la barra de
            // progreso esta presente, `pie` es mas alto que la fila de
            // miniaturas, y centrarse contra `parent` lo desalinearia hacia
            // abajo del contador y los botones de zoom.
            anchors { right: parent.right; verticalCenter: tira.verticalCenter }
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "PÁG. " + (root.pagina + 1) + " / " + root.total
                color: Theme.textMuted
                font.family: Theme.fontMono
                font.pixelSize: Theme.sizeMono
            }

            // Solo si hay PDF. Un boton que no hace nada es peor que no estar,
            // igual que una leyenda que miente (ui/Leyenda.qml).
            Boton {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.hayPdf
                texto: "PDF"
                variant: "glass"
                accent: root.accent
                atajo: "X"
                radio: 7
                implicitHeight: 24
                onActivado: root.abrirPdf(root.pdf)
            }

            Boton {
                texto: ""; glifo: "−"; variant: "glass"; accent: root.accent
                implicitWidth: 24; implicitHeight: 24
                onActivado: root.zoomear(-1)
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                horizontalAlignment: Text.AlignHCenter
                text: Math.round(root.zoom * 100) + "%"
                color: Theme.textBody
                font.family: Theme.fontMono
                font.pixelSize: Theme.sizeMono
            }

            Boton {
                texto: ""; glifo: "+"; variant: "glass"; accent: root.accent
                implicitWidth: 24; implicitHeight: 24
                onActivado: root.zoomear(1)
            }
        }
    }

    Text {
        id: leyenda
        // Anclada al borde REAL de la pantalla, no a `pie.top`: `pie` a su vez
        // se ancla a `leyenda.top` (ver arriba), asi que anclar los dos entre
        // si en el mismo eje seria un binding loop. Con altura fija, `pie`
        // sabe exactamente cuanto restarse sin que la leyenda dependa de nada
        // que dependa de ella.
        // -30% respecto al tamaño original (Theme.sizeMonoSm=10, height=20).
        // Es LOCAL a esta leyenda, no al token: Theme.sizeMonoSm sigue en 10
        // para todo lo demas que lo usa (subtitulos de ExtrasList, etc).
        readonly property int _tamano: 7
        height: 14
        verticalAlignment: Text.AlignVCenter
        anchors { bottom: parent.bottom; bottomMargin: 14; horizontalCenter: parent.horizontalCenter }
        color: Theme.textFaint
        font.family: Theme.fontMono
        font.pixelSize: _tamano
        font.letterSpacing: Theme.trackingLabel * _tamano
        // El tramo del PDF SOLO aparece cuando hay PDF: una leyenda que nombra
        // una tecla que no hace nada es peor que no tener leyenda
        // (ui/Leyenda.qml, con un bug real detras).
        text: {
            var t = "◄ ► PÁGINA";
            // Solo si aporta: con menos paginas que un salto, L2/R2 y ◄/►
            // hacen lo mismo -mencionarlo seria ruido, no ayuda (mismo
            // criterio que el tramo de PDF, que tampoco aparece si no hay).
            if (root.total > root._saltoGrande) t += "   L2 R2 SALTAR " + root._saltoGrande;
            // Contra puedePanearY y no contra el zoom: en los primeros pasos
            // la hoja todavia entra entera y ▲▼ no moverian nada. El mouse no
            // se nombra — esta leyenda es la del gabinete, que no tiene.
            if (root.puedePanearY) t += "   ▲ ▼ MOVER";
            t += "   + − ZOOM";
            if (root.hayPdf) t += "   X ABRIR PDF";
            return t + "   B CERRAR";
        }
    }

    // --- acciones ---------------------------------------------------------

    function irA(i) {
        if (i < 0 || i >= total) return;
        pagina = i;
        panX = 0;          // cambiar de pagina recentra: quedar perdido a mitad
        panY = 0;          // de la hoja anterior desorienta
    }

    // Como irA(), pero CLAMPEA en vez de descartar cuando el destino se pasa
    // del limite. Con delta=1 nunca se nota la diferencia (nunca se pide un
    // salto de mas de una posicion fuera de rango), pero con el salto grande
    // (L2/R2, +-10) estar en la pagina 95 de 100 y pedir +10 con irA() no
    // haria NADA - el usuario apreta el boton y no pasa nada, sin explicacion.
    // Clampeando, aterriza en la ultima pagina: "llegaste hasta donde se
    // podia" en vez de "tu boton no funciono".
    function saltar(delta) {
        irA(Math.max(0, Math.min(total - 1, pagina + delta)));
    }

    function zoomear(d) {
        var n = Math.max(0, Math.min(_zooms.length - 1, zoomIdx + d));
        if (n === zoomIdx) return;
        zoomIdx = n;
        if (zoom <= 1) { panX = 0; panY = 0; }
        else limitarPan();          // al alejarse, lo que sobraba puede ya no
                                    // sobrar: hay que volver a encuadrar
    }

    // Cuanto sobresale la PAGINA del escenario, de cada lado, en pixeles de
    // PANTALLA (ver el comentario del Translate en `hoja`).
    //
    // Se mide contra `paintedWidth/Height` y no contra `hoja`: la imagen entra
    // en la hoja con PreserveAspectFit, asi que es mas angosta que ella (446
    // dentro de 560, con una pagina retrato). Clampear por la hoja dejaria
    // arrastrar 32px de margen a 2.4x — papel vacio, sin nada nuevo que leer.
    //
    // Cuando la pagina no cargo, paintedWidth es 0 y no se panea nada: no hay
    // pagina, no hay nada que recorrer.
    readonly property real _sobraX:
        Math.max(0, (pagActual.paintedWidth * zoom - escenario.width) / 2)
    readonly property real _sobraY:
        Math.max(0, (pagActual.paintedHeight * zoom - escenario.height) / 2)

    function limitarPan() {
        panX = Math.max(-_sobraX, Math.min(_sobraX, panX));
        panY = Math.max(-_sobraY, Math.min(_sobraY, panY));
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            root.cerrar(); event.accepted = true;
        } else if (root.hayPdf && api.keys.isDetails(event)) {
            // X en el gamepad, I en el teclado (teclas-xy.qml). Se pregunta
            // DESPUES de isCancel y solo si hay PDF, para no comerse la tecla
            // cuando no hay nada que abrir.
            root.abrirPdf(root.pdf); event.accepted = true;
        } else if (api.keys.isPageUp(event) || api.keys.isPageDown(event)) {
            // Salto grande: L2/R2 en el gamepad. Se pregunta ANTES que
            // Key_Right/Key_Left porque en teclado esto llega como Fn+Flecha
            // (Key_Up/Key_Down con un modificador, no Key_Right/Left) y no
            // colisiona — pero el orden importa si Pegasus alguna vez lo
            // remapea distinto.
            root.saltar(api.keys.isPageUp(event) ? -_saltoGrande : _saltoGrande);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            root.irA(root.pagina + 1); event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.irA(root.pagina - 1); event.accepted = true;
        } else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
            root.zoomear(1); event.accepted = true;
        } else if (event.key === Qt.Key_Minus) {
            root.zoomear(-1); event.accepted = true;
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
            // Paneo con D-pad. SOLO vertical, y no por una limitacion del
            // contenido sino porque ◄ ► ya son pasar de pagina: darles un
            // segundo significado a partir de cierto zoom seria una sorpresa.
            // El eje horizontal existe (desde 3.2x), pero se arrastra con el
            // mouse. Ver el MouseArea `arrastre`.
            if (root.puedePanearY) {
                root.panY += (event.key === Qt.Key_Down ? -60 : 60);
                root.limitarPan();
                event.accepted = true;
            }
        }
    }
}
