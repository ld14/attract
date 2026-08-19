// El popover de VALOR, que abre/cierra el boton "−/+" cuando el modo es
// SELECCION. Diseño visual de
// design_handoff_home/year-letter-picker-spec.md — sort-select-spec.md
// sigue siendo la fuente de la LOGICA (que hace cada tecla, como se aplica
// el filtro); este archivo solo cambio como se ve.
//
// SOLO ES LA GRILLA, no criterio ni direccion — esos son botones propios y
// siempre visibles en la barra (screens/BrowseScreen.qml). Ver el
// encabezado viejo de este archivo en el historial de git si hace falta el
// razonamiento completo de por que se partio asi.
//
// 7 COLUMNAS FIJAS SIEMPRE, punto critico del spec nuevo (§Grilla de
// celdas): antes el año usaba menos columnas con celdas mas anchas para
// que "2024" entrara comodo. El spec pide EXACTAMENTE la misma estructura
// para letra y año — mismo ancho de celda, mismo gap — así el popover se ve
// igual en proporcion sin importar el criterio. La celda es lo bastante
// ancha para 4 digitos en mono a 15px; con letras (1 caracter) sobra lugar,
// y eso es intencional, no un descuido.

import QtQuick 2.0
import QtGraphicalEffects 1.0
import ".."

FocusScope {
    id: root

    property var catalogo: null
    property var teclas: null
    property color accent: Theme.accentNeutro

    // Donde cuelga el popover. BrowseScreen.qml pasa la esquina real de sus
    // controles; los valores por defecto son un fallback razonable si algo
    // lo instancia sin pasarlos.
    //
    // `width` y no Theme.canvasWidth: desde ADR-0019 el lienzo CRECE en el
    // eje que sobra, asi que el borde derecho real de la pantalla ya no es
    // canvasWidth. `width` es el ancho vigente (este FocusScope llena el
    // stage), y el default sigue significando lo mismo que antes: pegado al
    // gutter derecho.
    property real anclaX: width - Theme.gutter
    property real anclaY: 56

    signal cerrar()

    anchors.fill: parent

    readonly property var valores: {
        if (!catalogo) return [];
        if (catalogo.criterio === 0) {
            var l = ["#"];
            for (var i = 0; i < 26; i++) l.push(String.fromCharCode(65 + i));
            return l;
        }
        return catalogo.aniosDisponibles();
    }

    // --- geometria de la grilla, UNA sola vez, no repetida por celda -----
    // Escalado ~60% del original y despues +10% sobre eso (dos pedidos
    // explicitos seguidos, 2026-08-09) — mismas proporciones en las dos
    // pasadas, solo cambia el factor.
    readonly property int columnas: 7
    readonly property int celdaW: 29
    readonly property int celdaH: 26
    readonly property int gapCelda: 6
    readonly property int filasVisibles: 5

    readonly property int anchoGrilla: columnas * celdaW + (columnas - 1) * gapCelda
    readonly property int altoGrillaVisible: filasVisibles * celdaH + (filasVisibles - 1) * gapCelda
    // Piso de 1 fila: si `valores` llegara vacio por cualquier motivo (un
    // frame transitorio con `catalogo` todavia sin asentar, por ejemplo), el
    // panel se ve como una fila vacia en vez de colapsar a una pildora sin
    // contenido — la misma familia de bug que ya se vio una vez por el
    // binding loop de mas arriba (theme.qml), pero esto es la red de
    // seguridad para cualquier otra causa futura de `valores` vacio.
    readonly property int filasTotales: Math.max(1, Math.ceil(valores.length / columnas))
    readonly property int altoGrillaTotal:
        filasTotales * celdaH + Math.max(0, filasTotales - 1) * gapCelda

    property int _valorIdx: 0

    Component.onCompleted: {
        // Si ya hay un filtro puesto, el foco arranca sobre esa opcion y no
        // en la "#" — reabrir el popover para cambiar de letra no debería
        // obligar a recorrer toda la grilla desde el principio.
        if (catalogo && catalogo.filtro) {
            var i = root.valores.indexOf(catalogo.filtro.valor);
            if (i >= 0) root._valorIdx = i;
        }
    }

    // Sin scrim: el prototipo no oscurece nada detras del popover. Solo un
    // MouseArea invisible para que un click afuera cierre (uso de mouse; con
    // mando se cierra con B/X, o con el mismo boton "−" que lo abrio).
    MouseArea { anchors.fill: parent; onClicked: root.cerrar() }

    // La sombra va SEPARADA del panel (DropShadow con la fuente puesta,
    // no `layer.effect` sobre el panel mismo) porque el panel tiene su
    // propio borde de acento — envolverlo en layer.enabled activaria un
    // recorte que se comeria ese borde en los bordes redondeados.
    DropShadow {
        anchors.fill: panel
        source: panel
        radius: 24
        samples: 33
        spread: 0.15
        color: Qt.rgba(0, 0, 0, 0.55)
        verticalOffset: 10
        transparentBorder: true
    }

    Rectangle {
        id: panel
        anchors { right: parent.right; rightMargin: root.width - root.anclaX }
        anchors { top: parent.top; topMargin: root.anclaY + 6 }
        width: root.anchoGrilla + 18      // 9px de margen interno a cada lado
        radius: 10
        // Fondo oscuro casi opaco, como pide el spec (rgba(8,10,16,.95-.98)).
        color: Qt.rgba(0.031, 0.039, 0.063, 0.97)
        // El borde ENTERO del popover en el color de acento del juego
        // enfocado — no un gris generico. Punto critico del spec nuevo
        // (§Popover de grilla): "el borde entero del popover, no solo un
        // detalle".
        border.width: 1.1
        border.color: root.accent

        MouseArea { anchors.fill: parent }   // corta el click-afuera del padre

        // Textura de scanlines sutil, consistente con ui/Background.qml —
        // el spec pide "no un fondo liso" para el popover.
        Canvas {
            anchors.fill: parent
            opacity: 0.05
            renderStrategy: Canvas.Cooperative
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = "#ffffff";
                for (var y = 0; y < height; y += 3) ctx.fillRect(0, y, width, 1);
            }
        }

        Text {
            id: titulo
            anchors { top: parent.top; topMargin: 9; left: parent.left; leftMargin: 9 }
            text: root.catalogo && root.catalogo.criterio === 0
                  ? "ELEGIR LETRA" : "ELEGIR AÑO"
            color: root.accent
            font.family: Theme.fontMono
            font.bold: true
            font.pixelSize: 9
            font.letterSpacing: 0.1 * 9
        }

        Item {
            id: areaGrilla
            anchors { top: titulo.bottom; topMargin: 8; left: parent.left; leftMargin: 9 }
            width: root.anchoGrilla
            height: Math.min(root.altoGrillaVisible, root.altoGrillaTotal)

            Flickable {
                id: flick
                anchors.fill: parent
                contentWidth: width
                contentHeight: root.altoGrillaTotal
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: root.altoGrillaTotal > root.altoGrillaVisible

                // Mantiene la celda con foco de teclado siempre visible: sin
                // esto, ▼ mas alla de la 5ta fila mueve `_valorIdx` pero la
                // grilla no scrollea sola, y el mando "elige" celdas fuera
                // de pantalla.
                onContentHeightChanged: root._asegurarVisible()

                Repeater {
                    id: repeaterCeldas
                    model: root.valores

                    Rectangle {
                        readonly property int fila: Math.floor(index / root.columnas)
                        readonly property int col: index % root.columnas
                        x: col * (root.celdaW + root.gapCelda)
                        y: fila * (root.celdaH + root.gapCelda)
                        width: root.celdaW
                        height: root.celdaH

                        readonly property bool elegido:
                            root.catalogo.filtro
                            && root.catalogo.filtro.valor === modelData
                        readonly property bool enfocado: root._valorIdx === index

                        // Radio "notablemente mas redondeado que un chip
                        // cuadrado, pero no una pildora completa" (§Celda
                        // individual) — 8px sobre una celda de 26-29 no
                        // llega a pildora.
                        radius: 8
                        // Fondo casi negro en reposo, un toque mas claro que
                        // el panel — le da textura de "boton fisico".
                        color: elegido ? root.accent : "#14161c"
                        border.width: enfocado ? 1.7 : 0
                        border.color: root.accent

                        // ponytail: SIN el glow sutil que el spec pide para
                        // la celda elegida (§Estado seleccionado, "0 0 10px
                        // {acento}"). El fondo solido en acento + texto
                        // oscuro ya cumple el requisito principal del
                        // parrafo; el glow es el "ademas", y el spec mismo
                        // aclara que no se ve en ninguna de las dos capturas
                        // de referencia. Agregar cuando haga falta verificar
                        // contra Pegasus real con un filtro ya elegido.

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: elegido ? Theme.textOnAccent : "#dfe3ec"
                            font.family: Theme.fontMono
                            font.bold: true
                            font.pixelSize: 10
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root._elegir(index)
                        }
                    }
                }
            }

            // Scrollbar propia: Qt Quick 2.0 puro, sin QtQuick.Controls (no
            // hay experimento que confirme ese modulo en este binario —
            // Flickable.visibleArea si es nativo y alcanza para esto).
            // "delgada, en la esquina inferior derecha, discreta pero
            // perceptible" (§Popover de grilla).
            Rectangle {
                visible: flick.interactive
                anchors { right: parent.right; rightMargin: -4 }
                anchors { top: parent.top; bottom: parent.bottom }
                width: 2
                radius: 1
                color: Theme.alpha(Theme.textBright, 0.10)

                Rectangle {
                    width: parent.width
                    radius: parent.radius
                    color: Theme.alpha(root.accent, 0.65)
                    y: flick.visibleArea.yPosition * parent.height
                    height: Math.max(11, flick.visibleArea.heightRatio * parent.height)
                }
            }
        }

        height: areaGrilla.y + areaGrilla.height + 9
    }

    // SIN Leyenda a proposito — decision de producto, 2026-08-09, pedida
    // explicitamente: year-letter-picker-spec.md no la incluye en ninguna de
    // las dos capturas de referencia, y el diseño visual de este popover
    // prioriza verse igual a esas capturas por sobre el patron general de
    // leyenda-siempre-visible que exige el README (que este popover, a
    // diferencia del resto del theme, no sigue). ◄►▲▼ mueve el foco, A
    // confirma, B cierra — sigue funcionando igual, solo que ya no se anuncia
    // en pantalla.

    function _elegir(i) {
        root.catalogo.elegirValor(root.valores[i]);
        root.cerrar();
    }

    // Empuja el scroll lo justo para que la fila de `_valorIdx` quede
    // dentro de [visibleTop, visibleBottom] — no la centra, la ACERCA lo
    // minimo, que es lo que un usuario esperaria de "seguir" al foco.
    function _asegurarVisible() {
        var fila = Math.floor(root._valorIdx / root.columnas);
        var filaTop = fila * (root.celdaH + root.gapCelda);
        var filaBottom = filaTop + root.celdaH;
        if (filaTop < flick.contentY)
            flick.contentY = filaTop;
        else if (filaBottom > flick.contentY + flick.height)
            flick.contentY = filaBottom - flick.height;
    }

    Keys.onPressed: {
        if (!root.teclas || !root.catalogo) return;
        var d = root.teclas.direccion(event);
        var n = root.valores.length;

        if (root.teclas.esB(event) || root.teclas.esX(event)) {
            root.cerrar();
        } else if (d === "der") {
            root._valorIdx = Math.min(n - 1, root._valorIdx + 1);
            root._asegurarVisible();
        } else if (d === "izq") {
            root._valorIdx = Math.max(0, root._valorIdx - 1);
            root._asegurarVisible();
        } else if (d === "abajo") {
            root._valorIdx = Math.min(n - 1, root._valorIdx + root.columnas);
            root._asegurarVisible();
        } else if (d === "arriba") {
            root._valorIdx = Math.max(0, root._valorIdx - root.columnas);
            root._asegurarVisible();
        } else if (root.teclas.esA(event)) {
            root._elegir(root._valorIdx);
        } else {
            return;
        }
        event.accepted = true;
    }
}
