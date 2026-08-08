// Un estante: encabezado + fila horizontal de tarjetas.
//
// No sabe de donde salieron sus juegos ni por que estan en ese orden — eso lo
// decide core/Catalog.qml. Recibe un objeto {tipo, etiqueta, conteo, juegos} y
// lo dibuja.
//
// EL FOCO ANIDADO FUNCIONA SIN AYUDA, y se midio antes de escribir esto
// (themes/experimentos/estantes-perf.qml, 2026-08-05): este ListView
// horizontal se queda con izquierda/derecha y deja pasar arriba/abajo al
// ListView vertical de BrowseScreen. Cuando no puede moverse mas —primera o
// ultima tarjeta— tampoco acepta el evento, y ahi es donde la pantalla lo
// aprovecha para volver a la barra. El plan B (manejar las cuatro direcciones
// desde el FocusScope de la pantalla) quedo sin usar.

import QtQuick 2.0
import ".."
import "../ui"

FocusScope {
    id: root

    // { tipo, etiqueta, conteo, juegos: [game] }
    property var datos: null
    property var paths: null

    // Si este es el estante enfocado de la pantalla. Decide si sus tarjetas se
    // ven al 62% (vecinas) o al 50% (otro estante).
    property bool enfocado: false

    property color accent: Theme.accentNeutro
    property string chipOrden: ""      // "⇅ LETRA", solo en CATALOGO

    readonly property var juegos: (datos && datos.juegos) ? datos.juegos : []

    // El juego enfocado sale del ARRAY, no de lista.currentItem: currentItem es
    // null mientras el delegate no exista, y el hero de la pantalla se apagaria
    // en cada scroll largo.
    readonly property var juego:
        (lista.currentIndex >= 0 && lista.currentIndex < juegos.length)
        ? juegos[lista.currentIndex] : null

    property alias indice: lista.currentIndex

    signal activado(var game)

    // DIVERGE A PROPOSITO de los 192 literales del prototipo (:118). Esos
    // 192 le alcanzan AL PROTOTIPO porque el wrapper del track recorta contra
    // ese borde (`overflow:hidden`, :125); ese theme eligio NO recortar
    // (`lista.clip:false`, mas abajo), asi que copiar el numero sin copiar el
    // recorte deja la tarjeta enfocada asomando sobre su propio encabezado —
    // bug real visto en Pegasus el 2026-08-09 (dos rondas: primero se
    // intento con z-order solo, no alcanzo). El numero que sigue esta medido
    // para dar margen de verdad, no para calzar con el prototipo pixel a
    // pixel: cabecera(24) + margen(28) = 52 antes de la primera tarjeta, con
    // 8px de sobra despues de que la tarjeta enfocada suba sus ~20px.
    height: 218

    // El maximo de la fila, para que la barra de CONTINUAR JUGANDO sea
    // relativa a algo. Se calcula una vez por estante y no por tarjeta.
    readonly property real _maxTiempo: {
        if (!datos || datos.tipo !== "continuar") return 0;
        var m = 0;
        for (var i = 0; i < juegos.length; i++)
            if (juegos[i].playTime > m) m = juegos[i].playTime;
        return m;
    }

    // ------------------------------------------------------------ encabezado
    //
    // z:1 A PROPOSITO: es el area protegida del encabezado. La tarjeta
    // enfocada del PRIMER estante se eleva -12px y escala 1.05 (mismos
    // valores que el prototipo, :668), y esa elevacion puede asomar por
    // encima de la fila de tarjetas. El prototipo evita que eso tape el
    // encabezado con un `overflow:hidden` en el wrapper del track (:125) que
    // RECORTA la tarjeta contra ese borde — pero `lista.clip:false` es
    // deliberado aca (ver su propio comentario: sin eso, la tarjeta se
    // recorta al subir y escalar EN TODOS los estantes, no solo en el
    // primero). En vez de recortar, se invierte el orden de pintado: el
    // encabezado siempre gana. Bug real visto en Pegasus el 2026-08-09 —
    // "1993" de la carratula enfocada se superponia a "CATÁLOGO 10 juegos".
    Item {
        id: cabecera
        z: 1
        // leftMargin:10 compensa el colchon que BrowseScreen.qml le resto a
        // `estantes` — el texto sigue arrancando en Theme.gutter de siempre,
        // solo que ahora hay 10px de aire de mas a su izquierda, adentro del
        // area sin recorte.
        anchors { top: parent.top; left: parent.left; leftMargin: 10; right: parent.right }
        height: 24

        // La regla que se extiende hacia la derecha, como en el diseño. Va
        // ANCLADA al Row y no dentro de el: un hijo de Row que quiere ocupar
        // "lo que sobra" necesita saber el ancho del Row, y el Row saca su
        // ancho de los hijos — el circulo que QML no resuelve
        // (docs/plataforma-pegasus.md §3, ultima fila de la tabla).
        Rectangle {
            anchors { left: titulos.right; leftMargin: 16; right: parent.right }
            anchors.verticalCenter: parent.verticalCenter
            height: 1
            // Blanco al 8% y NO en accent: en el prototipo es
            // `linear-gradient(90deg, rgba(255,255,255,.08), transparent)`
            // (:124) — una separacion, no un subrayado. En accent y a full
            // parecia una barra de progreso cruzando la pantalla.
            color: Theme.alpha(Theme.textBright, 0.08)
        }

        Row {
            id: titulos
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            // Chakra Petch 700 15px, ls .04em (prototipo :675). El estante sin
            // foco no se apaga hasta el gris de las etiquetas: queda en #aab0bf,
            // que sigue siendo legible — son titulos de seccion, no adorno.
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.datos ? root.datos.etiqueta : ""
                color: root.enfocado ? "#f1f3f8" : "#aab0bf"
                font.family: Theme.fontDisplay
                font.bold: true
                font.pixelSize: 15
                font.letterSpacing: 0.04 * 15
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.datos ? root.datos.conteo : ""
                color: "#5b6173"
                font.family: Theme.fontMono
                font.pixelSize: 10
                font.letterSpacing: 0.1 * 10
            }

            // El criterio activo se ve solo donde de verdad manda: los otros
            // tres estantes tienen su propio orden y no lo respetan.
            //
            // No usa ui/Chip.qml: ese mide 28 de alto y aca el encabezado
            // entero mide 20. Son 9px de mono en una pastilla de 2x7, del
            // prototipo (:121).
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.chipOrden !== ""
                width: critLbl.implicitWidth + 14
                height: critLbl.implicitHeight + 4
                radius: height / 2
                color: "transparent"
                border.width: 1
                border.color: Theme.alpha(root.accent, 0.30)

                Text {
                    id: critLbl
                    anchors.centerIn: parent
                    text: root.chipOrden
                    color: root.accent
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.letterSpacing: 0.1 * 9
                }
            }
        }
    }

    // ---------------------------------------------------------------- fila
    ListView {
        id: lista
        // 28 y no 11: ver la nota de `height` mas arriba. Da 8px de sobra
        // despues de que la tarjeta enfocada suba ~20px al elevarse.
        anchors { top: cabecera.bottom; topMargin: 28 }
        // leftMargin:10, mismo colchon que cabecera (ver la nota de
        // BrowseScreen.qml sobre `estantes`) — sin esto la primera tarjeta
        // enfocada de cada estante crece hacia la izquierda al escalar y
        // choca contra el borde de clip de `estantes`.
        anchors { left: parent.left; leftMargin: 10; right: parent.right }
        height: 166

        orientation: ListView.Horizontal
        spacing: 16
        model: root.juegos
        focus: true
        keyNavigationWraps: false

        // Sin esto la tarjeta enfocada se recorta al subir y al escalar.
        clip: false

        // La tarjeta enfocada queda en la 2a ranura, como el diseño.
        // ApplyRange y no StrictlyEnforceRange: Strictly obliga al rango
        // tambien en los extremos, asi que con currentIndex 0 empuja la primera
        // tarjeta a la segunda ranura y deja el estante arrancando despegado
        // del margen. ApplyRange respeta los limites del contenido.
        preferredHighlightBegin: 148 + 16
        preferredHighlightEnd: 2 * (148 + 16)
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 260

        // Una pantalla de tarjetas a cada lado. Con el pico medido en 47
        // delegates vivos, el margen alcanza para que scrollear rapido no
        // muestre huecos sin instanciar de mas.
        cacheBuffer: 400

        delegate: GameCard {
            game: modelData
            paths: root.paths
            variacion: index
            activo: ListView.isCurrentItem
            atenuado: !root.enfocado

            rango: (root.datos && root.datos.tipo === "jugados") ? index + 1 : -1
            progreso: (root.datos && root.datos.tipo === "continuar"
                       && root._maxTiempo > 0)
                      ? modelData.playTime / root._maxTiempo : -1

            onActivado: {
                // Patron TV: el primer toque enfoca, el segundo abre. En un
                // gabinete con joystick, entrar al primer toque hace imposible
                // recorrer la libreria.
                if (lista.currentIndex === index) root.activado(modelData);
                else lista.currentIndex = index;
            }
        }
    }
}
