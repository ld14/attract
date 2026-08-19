// La libreria: barra superior, hero del juego enfocado y los estantes.
// Reemplaza a LibraryScreen.qml (rail unico), que se borra.
//
// DOS REGIONES, DOS FocusScope. El prototipo lleva una variable
// `region: 'tabs' | 'shelves'` y un onKey(e) global que la consulta
// (design_handoff_home/Pegasus Home.dc.html:567-618). Aca esa variable no
// existe: son dos FocusScope y "cambiar de region" es mover el foco. La
// leyenda del pie lee quien tiene activeFocus, asi que no hay dos estados que
// sincronizar ni forma de que se contradigan.
//
// COMO SE VUELVE A LA BARRA SIN INTERCEPTAR NADA: un ListView que no puede
// moverse mas NO acepta el evento (medido, themes/experimentos/estantes-perf.qml).
// Asi que ▲ desde el primer estante sube sola hasta el Keys.onPressed de esta
// pantalla. No hace falta preguntar currentIndex === 0 en ningun lado; si
// llego hasta aca es porque nadie mas la quiso.

import QtQuick 2.0
import ".."
import "../core"
import "../ui"

FocusScope {
    id: root

    property var paths: null
    property var teclas: null
    property var catalogo: null

    property string wordmark: "SHINBOX"

    // El estante y el juego enfocados, para el hero y para que theme.qml tiña
    // el fondo con el accent del juego.
    readonly property var estanteActual: estantes.currentItem
    readonly property var juego: estanteActual ? estanteActual.juego : null

    // El accent sale del GameData de ESTA pantalla y NO del estante enfocado.
    // Leerlo del estante cerraba un ciclo —root.accent -> estante.accent ->
    // root.accent, porque el estante lo recibe de aca— y QML ante un binding
    // loop se queda con el valor por defecto: todo el accent del juego se veia
    // gris neutro. Se vio en Pegasus el 2026-08-06 con el boton VER DETALLE.
    readonly property color accent: datos.accent

    signal abrirDetalle(var game)
    signal lanzar(var game)
    signal abrirAyuda()
    signal abrirOrden()
    signal cerrarOrden()
    signal abrirBuscar()

    // El toggle del popover de valor (design_handoff_home/
    // year-letter-picker-spec.md §Barra de controles, boton 3): BrowseScreen
    // es quien sabe si esta abierto porque el boton "−/+" necesita mostrar
    // el icono correcto y actuar como TOGGLE, no como "abrir nomas". El
    // Loader que de verdad monta el popover vive en theme.qml (`orden`), que
    // sincroniza este valor de vuelta a false en CUALQUIER cierre —
    // eligiendo un valor, B/X adentro del popover, o click afuera— porque
    // todos esos caminos ya funnelean por la misma señal `cerrar()` del
    // popover.
    property bool popoverOrdenAbierto: false

    GameData {
        id: datos
        game: root.juego
        paths: root.paths
    }

    // Las plataformas del juego enfocado, hasta 4 como el diseño (:682).
    // `collections` es un modelo de Qt: tiene count y get(), no length.
    readonly property var plataformas: {
        if (!juego || !juego.collections) return [];
        var out = [];
        for (var i = 0; i < Math.min(4, juego.collections.count); i++)
            out.push(String(juego.collections.get(i).name).toUpperCase());
        return out;
    }

    // Un `game:` con varios `file:` es UN juego con varias ediciones
    // (ADR-0004), y el selector de plataforma del detalle sale de ahi.
    readonly property int ediciones:
        (juego && juego.files) ? juego.files.count : 0

    // ---------------------------------------------------------------- barra
    FocusScope {
        id: barra
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors { topMargin: 22; leftMargin: Theme.gutter; rightMargin: Theme.gutter }
        height: 34

        // --- izquierda: logo, wordmark y PESTAÑAS. Las pestañas van aca y no
        // a la derecha: en el prototipo cuelgan del mismo contenedor que el
        // wordmark (:44-53), pegadas a el.
        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: 12

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 13; height: 13; radius: 3
                color: root.accent
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.wordmark
                color: Theme.textPrimary
                font.family: Theme.fontDisplay
                font.bold: true
                font.pixelSize: 15
                font.letterSpacing: 0.16 * 15
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "ARCADE"
                color: Theme.textFaint
                font.family: Theme.fontDisplay
                font.pixelSize: 15
                font.letterSpacing: 0.16 * 15
            }

            Item { width: 8; height: 1 }

            // Dos pestañas, no cuatro: TODOS y FAVORITOS es lo que define el
            // handoff; las cuatro que dibujaba LibraryScreen eran del mockup
            // anterior y ademas no filtraban nada.
            Repeater {
                model: root.catalogo ? root.catalogo.pestanas : []

                Rectangle {
                    id: pastilla
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property bool activa: root.catalogo.pestana === index
                    readonly property bool enfocada: barra.focoClamp === barra._indiceDe("tab" + index)

                    // padding 7px 13px, radius 8 (:635). Antes era una pildora
                    // full-round de dos renglones; el diseño la quiere
                    // rectangular y con el conteo EN LINEA.
                    width: fila.width + 26
                    height: fila.height + 14
                    radius: 8
                    color: activa ? root.accent : Theme.glassFill
                    border.width: activa ? 0 : 1
                    border.color: Theme.alpha(Theme.textBright, 0.08)
                    Behavior on color { ColorAnimation { duration: 180 } }

                    // El anillo blanco que el prototipo le pone a la pestaña
                    // activa cuando la region enfocada es la barra.
                    Rectangle {
                        anchors { fill: parent; margins: -2 }
                        radius: 10
                        color: "transparent"
                        border.width: 2
                        border.color: Theme.alpha(Theme.textBright, 0.40)
                        visible: pastilla.enfocada
                    }

                    Row {
                        id: fila
                        anchors.centerIn: parent
                        spacing: 7

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData
                            color: pastilla.activa ? Theme.textOnAccent : "#9aa0b0"
                            font.family: Theme.fontDisplay
                            font.bold: true
                            font.pixelSize: 13
                            font.letterSpacing: 0.04 * 13
                        }

                        // El conteo real, como pide el handoff. No es adorno:
                        // es lo unico que dice si FAVORITOS tiene algo antes de
                        // entrar y encontrarlo vacio.
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.catalogo.conteoDe(index)
                            color: pastilla.activa
                                   ? Theme.alpha(Theme.textOnAccent, 0.75) : "#5b6173"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.letterSpacing: 0.06 * 9
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            barra.foco = barra._indiceDe("tab" + index);
                            root.catalogo.pestana = index;
                        }
                    }
                }
            }
        }

        // --- derecha: MODO, CRITERIO, el Boton 3 contextual, el chip de
        // limpiar filtro, BUSCAR, reloj y ayuda.
        //
        // REVERTIDO el 2026-08-09: la primera pasada de
        // year-letter-picker-spec.md llevo MODO/CRITERIO a pill completo de
        // 40px en mono con tracking ancho, tal cual sus capturas — pero eso
        // clasheaba contra CADA OTRO boton de esta misma barra (BUSCAR, "?",
        // las pestañas), que usan radio 8 / 30px / Chakra Petch en todo el
        // resto del theme. Cuando dos spec entran en conflicto (el pixel
        // literal de un componente nuevo vs. la consistencia de TODO el
        // theme ya construido), gana la consistencia — es la misma logica
        // que ya aplico el "Decisiones" de plan.md §8 al superar la version
        // vieja del panel unico. Se conserva el CONTENIDO funcional del
        // spec (MODO resaltado en acento cuando es SELECCION, el toggle
        // dedicado) con el idioma visual YA establecido: `Boton.qml`,
        // igual que BUSCAR/ayuda, en vez de un componente a mano nuevo.
        Row {
            id: filaControles
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 6

            // El resaltado en acento cuando el modo es SELECCION usa el
            // MISMO mecanismo que ya prueba la pestaña activa mas arriba en
            // esta misma barra (variant accent = relleno solido de acento):
            // no es una idea nueva, es reusar el "esto esta activo" que el
            // theme ya sabe dibujar.
            Boton {
                radio: 8
                implicitHeight: 30
                texto: root.catalogo ? (root.catalogo.modo === 0 ? "ORDEN" : "SELECCIÓN") : "ORDEN"
                variant: (root.catalogo && root.catalogo.modo === 1) ? "accent" : "glass"
                accent: root.accent
                activo: barra.focoClamp === barra._indiceDe("modo")
                onActivado: { barra.foco = barra._indiceDe("modo"); barra._activar("modo"); }
            }

            Rectangle {
                id: pillCriterio
                anchors.verticalCenter: parent.verticalCenter
                readonly property bool enfocado: barra.focoClamp === barra._indiceDe("criterio")
                width: crit.implicitWidth + 24
                height: 30
                radius: 8
                color: Theme.glassFill
                border.width: 1
                border.color: enfocado ? Theme.alpha(Theme.textBright, 0.40)
                                       : Theme.alpha(Theme.textBright, 0.10)

                Text {
                    id: crit
                    anchors.centerIn: parent
                    text: root.catalogo ? root.catalogo.criterios[root.catalogo.criterio] : ""
                    color: "#dfe3ec"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.letterSpacing: 0.06 * 11
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: { barra.foco = barra._indiceDe("criterio"); barra._activar("criterio"); }
                }
            }

            // Boton 3 · variante DIRECCION — Orden con Letra o Año.
            Rectangle {
                id: pillDireccion
                anchors.verticalCenter: parent.verticalCenter
                readonly property bool enfocado: barra.focoClamp === barra._indiceDe("direccion")
                visible: root.catalogo && root.catalogo.direccionAplica
                width: 30; height: 30
                radius: 8
                color: Theme.glassFill
                border.width: 1
                border.color: enfocado ? Theme.alpha(Theme.textBright, 0.40)
                                       : Theme.alpha(Theme.textBright, 0.10)

                Text {
                    anchors.centerIn: parent
                    text: (root.catalogo && root.catalogo.direccion === 1) ? "▲" : "▼"
                    color: root.accent
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        barra.foco = barra._indiceDe("direccion");
                        barra._activar("direccion");
                    }
                }
            }

            // Boton 3 · variante TOGGLE "−/+" — modo Seleccion. Es lo unico
            // de esta fila que SI es un componente nuevo (no existia antes
            // de year-letter-picker-spec.md): reemplaza al boton que
            // mostraba el valor elegido como texto, ahora es un toggle real
            // que abre/cierra el popover (root.popoverOrdenAbierto decide
            // el icono). Se mantiene 30x30/radio 8 como el resto de la
            // barra; lo unico que lo distingue —como pide el spec— es que
            // su borde de acento esta SIEMPRE puesto, resaltado o no.
            Rectangle {
                id: pillToggle
                anchors.verticalCenter: parent.verticalCenter
                readonly property bool enfocado: barra.focoClamp === barra._indiceDe("popover")
                visible: root.catalogo && root.catalogo.valorAplica
                width: 30; height: 30
                radius: 8
                color: enfocado ? Theme.glassFillHi : Theme.glassFill
                border.width: 1
                border.color: root.accent

                Text {
                    anchors.centerIn: parent
                    text: root.popoverOrdenAbierto ? "−" : "+"
                    color: root.accent
                    font.family: Theme.fontBody
                    font.bold: true
                    font.pixelSize: 15
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: { barra.foco = barra._indiceDe("popover"); barra._activar("popover"); }
                }
            }

            // §Filtro activo: el chip "✕ LETRA C" / "✕ AÑO 1992". Limpiarlo
            // NO dispara el reseteo de navegacion (eso es solo al ELEGIR un
            // valor nuevo, sort-select-spec.md §Reseteo de navegación) — por
            // eso pone `filtro = null` directo y no pasa por elegirValor().
            Boton {
                radio: 8
                implicitHeight: 30
                visible: root.catalogo && root.catalogo.filtro !== null
                texto: root.catalogo && root.catalogo.filtro
                       ? "✕ " + (root.catalogo.filtro.campo === "letra" ? "LETRA " : "AÑO ")
                         + root.catalogo.filtro.valor
                       : ""
                variant: "glass"
                accent: root.accent
                activo: barra.focoClamp === barra._indiceDe("limpiar")
                onActivado: { barra.foco = barra._indiceDe("limpiar"); barra._activar("limpiar"); }
            }

            Item { width: 8; height: 1 }

            // BUSCAR lleva su atajo a la vista: en un gabinete sin teclado ni
            // mouse es la unica pista de que Y hace algo.
            Boton {
                radio: 8   // el prototipo usa 8px para los botones de HUD, no el 10 default
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: 30
                texto: "BUSCAR"
                glifo: "⌕"
                atajo: "Y"
                variant: "glass"
                accent: root.accent
                activo: barra.focoClamp === barra._indiceDe("buscar")
                onActivado: { barra.foco = barra._indiceDe("buscar"); barra._activar("buscar"); }
            }

            Item { width: 8; height: 1 }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1; height: 16
                color: Theme.alpha(Theme.textBright, 0.12)
            }

            Text {
                id: reloj
                anchors.verticalCenter: parent.verticalCenter
                color: "#7c8294"
                font.family: Theme.fontMono
                font.pixelSize: 12
                font.letterSpacing: 0.08 * 12
                text: "--:--"

                // Cada 20s y no cada segundo: no hay segundero en pantalla,
                // despertar cada segundo solo gasta.
                Timer {
                    interval: 20000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        var d = new Date();
                        reloj.text = ("0" + d.getHours()).slice(-2) + ":"
                                   + ("0" + d.getMinutes()).slice(-2);
                    }
                }
            }

            Boton {
                radio: 8   // el prototipo usa 8px para los botones de HUD, no el 10 default
                anchors.verticalCenter: parent.verticalCenter
                texto: ""; glifo: "?"; variant: "glass"; accent: root.accent
                implicitWidth: 30; implicitHeight: 30
                activo: barra.focoClamp === barra._indiceDe("ayuda")
                onActivado: { barra.foco = barra._indiceDe("ayuda"); barra._activar("ayuda"); }
            }
        }

        // El foco de la barra es UN SOLO INDICE PLANO sobre TODOS sus
        // controles interactivos —pestañas + modo + criterio + boton 3 +
        // limpiar + buscar + ayuda—, no dos regiones separadas. Es como se
        // lee la barra de izquierda a derecha, y es lo que
        // sort-select-spec.md pide para el modo/criterio/boton3: "foco
        // direccional + Enter/A también los activa, como cualquier botón
        // enfocable" (§Atajo de teclado/joystick) — no un gesto especial.
        //
        // `_slots()` es una funcion y no una property por una razon
        // concreta: el SET de controles visibles cambia solo (boton3 aparece
        // o no segun modo+criterio, limpiar segun haya filtro), asi que la
        // lista tiene que recalcularse cada vez que se la usa. QML igual seq
        // engancha en las lecturas de propiedades que pasan por adentro
        // (catalogo.modo, catalogo.filtro, etc.), asi que sigue siendo
        // reactiva donde se la lee desde un binding.
        property int foco: 0
        readonly property int focoClamp: Math.max(0, Math.min(foco, _slots().length - 1))

        function _slots() {
            var s = [];
            var np = root.catalogo ? root.catalogo.pestanas.length : 0;
            for (var i = 0; i < np; i++) s.push("tab" + i);
            s.push("modo");
            s.push("criterio");
            if (root.catalogo && root.catalogo.direccionAplica) s.push("direccion");
            else if (root.catalogo && root.catalogo.valorAplica) s.push("popover");
            if (root.catalogo && root.catalogo.filtro) s.push("limpiar");
            s.push("buscar");
            s.push("ayuda");
            return s;
        }

        function _indiceDe(nombre) { return _slots().indexOf(nombre); }

        function _activar(slot) {
            if (!slot || !root.catalogo) return;
            if (slot.indexOf("tab") === 0) {
                // A sobre una pestaña CONFIRMA y baja a los estantes — el
                // comportamiento de siempre de la region "tabs" (README:
                // "▼/Enter baja a los estantes"). Los controles de
                // orden/seleccion no heredan esto: A sobre ellos activa el
                // control puntual, se quedan en la barra.
                root.catalogo.pestana = parseInt(slot.substring(3), 10);
                estantes.focus = true;
            }
            else if (slot === "modo") root.catalogo.alternarModo();
            else if (slot === "criterio") root.catalogo.ciclarCriterio(1);
            else if (slot === "direccion") root.catalogo.direccion = -root.catalogo.direccion;
            else if (slot === "popover") {
                // Toggle real: si ya esta abierto, este mismo boton lo
                // cierra — year-letter-picker-spec.md §Barra de controles
                // punto 3 lo describe como boton de abrir/cerrar, no de
                // "solo abrir".
                if (root.popoverOrdenAbierto) {
                    root.cerrarOrden();
                    root.popoverOrdenAbierto = false;
                } else {
                    root.abrirOrden();
                    root.popoverOrdenAbierto = true;
                }
            }
            else if (slot === "limpiar") root.catalogo.filtro = null;
            else if (slot === "buscar") root.abrirBuscar();
            else if (slot === "ayuda") root.abrirAyuda();
        }

        Keys.onPressed: {
            if (!root.catalogo) return;
            var d = root.teclas.direccion(event);
            var n = _slots().length;

            if (d === "izq") { foco = Math.max(0, focoClamp - 1); event.accepted = true; }
            else if (d === "der") { foco = Math.min(n - 1, focoClamp + 1); event.accepted = true; }
            else if (d === "abajo") { estantes.focus = true; event.accepted = true; }
            else if (root.teclas.esA(event)) {
                _activar(_slots()[focoClamp]);
                event.accepted = true;
            }
        }
    }

    // ----------------------------------------------------------------- hero
    // EL HERO VIVE DENTRO DE UNA CAJA DE ALTO CONOCIDO, y esa caja es la
    // correccion de un bug que ya se cobro tres veces (docs/plataforma-pegasus.md
    // §3, "crecer hacia arriba sin tope"). El diseño lo quiere pegado abajo y
    // creciendo hacia arriba; una Column hace exactamente eso y NO tiene tope,
    // asi que con las fuentes reales crecio de mas y se metio en la barra —
    // visto en Pegasus el 2026-08-03 con el rail, y otra vez el 2026-08-06 con
    // los estantes, donde el eyebrow quedo dibujado ENCIMA del wordmark.
    //
    // La caja se ancla a la barra y a los estantes, asi que su alto es el
    // espacio disponible de verdad y no depende de sus hijos. El `clip` es la
    // red de seguridad: si el calculo vuelve a fallar, el hero se corta, pero
    // NO invade la barra.
    //
    // EL CTA ("VER DETALLE") ESTA FIJO AL PISO DE LA CAJA, y esa es la
    // correccion de un bug real visto en Pegasus el 2026-08-08: la version
    // anterior le daba al TITULO "lo que sobra" (heroBox.height menos el resto)
    // con un piso de 48px. Con un titulo de dos renglones reales — no
    // "Striker", sino "Street Fighter II': Champion Edition (World 920513)",
    // que es lo que devuelve MAME — ese piso de 48 no alcanza ni para el
    // minimo del clamp (2 lineas a 36px = 65px), Text.Fit desborda su propia
    // caja, y en el peor caso el Column entero termina midiendo mas que
    // heroBox: el CTA queda debajo del borde de clip y desaparece.
    //
    // La correccion es la misma leccion que ya dejaron tres bugs anteriores
    // de esta familia (docs/plataforma-pegasus.md §3): cuando el layout lo
    // calcula uno en vez de anclarlo, funciona hasta que cambia un dato real.
    // Ahora CADA bloque tiene una posicion fija por anchor — eyebrow arriba,
    // acciones abajo del todo — y el UNICO elastico es la sinopsis, que ya
    // tiene su propio manejo de "no hay espacio" (maximumLineCount + elide +
    // clip). El CTA no se mueve nunca, sin importar cuanto mida el titulo.
    Item {
        id: heroBox
        anchors { left: parent.left; leftMargin: Theme.gutter }
        // top:84px, left:48px, width:600px — literal del prototipo (:87).
        //
        // El top va por ANCHOR y no por `y`: un Item no tiene alto implicito,
        // asi que con solo `anchors.bottom` puesto su altura queda en CERO y
        // el clip se traga el hero entero. Paso el 2026-08-06 — la pantalla
        // salio con toda la mitad superior vacia.
        anchors { top: parent.top; topMargin: 84 }
        anchors { bottom: estantes.top; bottomMargin: 12 }
        width: 600
        clip: true

        // Item y no Column: cada bloque va anclado por separado. Con un Column
        // el alto de CUALQUIER hijo empuja a todos los que siguen — que es
        // exactamente el mecanismo del bug de arriba. Ancladas, la posicion de
        // "acciones" no depende de lo que midan sus vecinos.
        Item {
            id: hero
            anchors.fill: parent

            // Los chips de plataforma. No usan ui/Chip.qml: ese es la pastilla
            // clave/valor del detalle —28px de alto, full-round, y con el
            // "Sin Informacion" de CONVENCION §2.3 adentro— y aca el diseño
            // quiere rectangulos chicos de radio 5 (:682). Un juego sin
            // coleccion no muestra un chip que diga que no hay dato: no
            // muestra chip.
            Row {
                id: eyebrow
                anchors { left: parent.left; right: parent.right; top: parent.top }
                spacing: 7
                height: 24

                Repeater {
                    model: root.plataformas

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: nombre.implicitWidth + 18      // padding 4px 9px
                        height: nombre.implicitHeight + 8
                        radius: 5
                        color: Theme.alpha(Theme.textBright, 0.05)
                        border.width: 1
                        border.color: Theme.alpha(Theme.textBright, 0.16)

                        Text {
                            id: nombre
                            anchors.centerIn: parent
                            text: modelData
                            color: "#c2c6d2"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.letterSpacing: 0.06 * 10
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.ediciones > 1
                    text: root.ediciones + " EDICIONES"
                    color: Theme.textFaint
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.letterSpacing: 0.1 * 9
                }
            }

            Text {
                id: titulo
                anchors { left: parent.left; right: parent.right }
                anchors { top: eyebrow.bottom; topMargin: 14 }   // margin-bottom:14 del chip (:98)

                // FIJA en 68: alcanza para DOS renglones incluso al piso del
                // clamp (2 × 36px × lineHeight .90 ≈ 65px). Ya no depende de
                // sus vecinos, asi que no puede volver a empujar el CTA fuera
                // de la caja — ver la nota de heroBox arriba.
                height: 68

                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Theme.textBright
                font.family: Theme.fontDisplay
                font.bold: true
                lineHeight: 0.90                    // line-height:.9 (:98)
                font.letterSpacing: -0.01 * 62      // letter-spacing:-.01em
                verticalAlignment: Text.AlignTop

                // clamp(36px, 4.6vw, 62px) del handoff. Con el lienzo fijo el
                // termino del medio colapsa (ADR-0016), pero el piso del clamp es
                // real: MAME devuelve titulos como "Street Fighter II': Champion
                // Edition (World 920513)", que a tamaño fijo se corta con elipsis.
                fontSizeMode: Text.Fit
                font.pixelSize: 62
                minimumPixelSize: 36

                text: root.juego ? root.juego.title : ""
            }

            // El renglon de metadata del diseño: "genero · año · jugadores" y
            // el chip de nota al final. El genero va en accent y el resto en
            // gris, asi que son dos Text con el separador en el medio en vez
            // de un solo string — el "·" tiene que verse igual que los que
            // arma el join, de ahi el mismo doble espacio.
            Row {
                id: meta
                anchors { left: parent.left; top: titulo.bottom; topMargin: 14 }
                spacing: 0

                Text {
                    id: genero
                    anchors.verticalCenter: parent.verticalCenter
                    text: (root.juego && root.juego.genre) ? root.juego.genre : ""
                    visible: text !== ""
                    color: root.accent
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    font.letterSpacing: 0.06 * 12
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: genero.visible && resto.text !== ""
                    text: "  ·  "
                    color: Theme.textFaint
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.sizeMono
                }

                Text {
                    id: resto
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#9aa0b0"
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    font.letterSpacing: 0.06 * 12
                    text: {
                        if (!root.juego) return "";
                        var p = [];
                        // releaseYear 0 y players 1 son valores por default, no
                        // datos (docs/plataforma-pegasus.md §2). El año se omite;
                        // los jugadores se muestran porque un 1 en un juego retro
                        // casi nunca es una mentira dañina.
                        if (root.juego.releaseYear > 0) p.push(root.juego.releaseYear);
                        // "2 jug.", como el diseño (:789) — no "2 JUGADORES".
                        if (root.juego.players > 0) p.push(root.juego.players + " jug.");
                        return p.join("  ·  ");
                    }
                }

                Item { width: 14; height: 1 }

                // La nota sale de data.json, NO del `rating` nativo: ese vuelve
                // 0.0 por default y no distingue "sin nota" de "nota cero"
                // (ADR-0015, y el mismo criterio que usa ReviewCard). Sin
                // reseña el chip no se dibuja — es un dato que no existe, no un
                // bloque que falta.
                Rectangle {
                    id: chipNota
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property bool hayNota:
                        datos.review !== null && typeof datos.review.score === "number"

                    visible: hayNota
                    width: filaNota.width + 18       // padding 3px 9px
                    height: filaNota.height + 6
                    radius: height / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.alpha(root.accent, 0.40)

                    Row {
                        id: filaNota
                        anchors.centerIn: parent
                        spacing: 6

                        // El rombo del diseño es un cuadrado de 5px girado 45°.
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 5; height: 5
                            color: root.accent
                            rotation: 45
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: chipNota.hayNota ? datos.review.score + "/100" : ""
                            color: root.accent
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            font.letterSpacing: 0.06 * 12
                        }
                    }
                }
            }

            Text {
                id: sinopsis
                // El UNICO elastico del hero. Ancla top Y bottom: su alto es
                // lo que sobra entre meta y acciones, sin que su calculo
                // pueda afectar a nadie mas — acciones ya esta fijo al piso
                // de la caja por su propio anchor, no por este.
                anchors { left: parent.left; top: meta.bottom; topMargin: 16 }
                anchors { bottom: acciones.top; bottomMargin: 18 }
                // max-width:520px del prototipo (:105) — heroBox mide 600, asi
                // que sin este tope el texto usaba los 600 enteros. width fijo
                // y NO anchors.right: no pueden convivir los dos en el mismo eje.
                width: 520
                clip: true
                wrapMode: Text.WordWrap
                // Dos renglones como techo, pero si el espacio real da menos
                // (titulo largo de 2 lineas + meta grande), el sobrante corta
                // por el clip de arriba en vez de invadir al CTA.
                maximumLineCount: 2
                elide: Text.ElideRight
                // 15px / 1.55 / #aeb3c0 — el prototipo (:104). Theme.sizeBody
                // es 16 y viene del detalle, que es otra pantalla.
                color: "#aeb3c0"
                font.family: Theme.fontBody
                font.pixelSize: 15
                lineHeight: 1.55
                // summary lo escribe attract synopsis (ADR-0011). Sin el, el bloque
                // no desaparece: dice que no hay dato (CONVENCION §2.3).
                text: (root.juego && root.juego.summary) ? root.juego.summary
                                                         : "Sin Informacion"
            }

            Row {
                id: acciones
                anchors { left: parent.left; bottom: parent.bottom }
                spacing: 14

                Boton {
                    radio: 8   // el prototipo usa 8px para los botones de HUD, no el 10 default
                    // 42 y no los 48 por defecto: en el diseño el CTA del hero
                    // es mas bajo que los botones del detalle.
                    implicitHeight: 42
                    texto: "VER DETALLE"
                    glifo: "▤"
                    atajo: "A"
                    variant: "accent"
                    accent: root.accent
                    onActivado: root.abrirDetalle(root.juego)
                }

                // La nota de plataforma del diseño (:791). Dice donde se puede
                // jugar y adelanta que la eleccion se hace en el detalle —
                // sin esto, un juego con tres ediciones no da ninguna pista de
                // que hay algo que elegir.
                //
                // Antes aca se listaban REVISTAS / TRUCOS / MANUAL. Eso ya se
                // ve en los puntitos de la tarjeta, y el renglon del diseño
                // responde otra pregunta.
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""
                    color: Theme.textFaint
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.letterSpacing: 0.04 * 11
                    text: {
                        if (root.plataformas.length === 0) return "";
                        if (root.ediciones > 1)
                            return "Disponible en " + root.ediciones
                                 + " ediciones · elegís en el detalle";
                        return "Plataforma: " + root.plataformas[0];
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------- estantes
    ListView {
        id: estantes
        anchors { left: parent.left; right: parent.right }
        // Theme.gutter MENOS un colchon de 10, y no Theme.gutter a secas: la
        // primera tarjeta de cada estante queda pegada al borde izquierdo de
        // esta lista, que tiene clip:true. Al enfocarse escala 1.05 desde su
        // CENTRO (GameCard.qml), asi que crece ~4px hacia la izquierda —
        // crecimiento que sin este colchon se recorta contra el borde,
        // dejando el canto redondeado con pinta de cortado. Shelf.qml
        // compensa con leftMargin:10 en cabecera y en la fila, asi que el
        // texto y las tarjetas siguen empezando visualmente en Theme.gutter
        // de siempre — lo unico que cambia es que ahora hay 10px de colchon
        // ANTES de ese punto, adentro del area que este ListView no recorta.
        // Bug real visto en Pegasus el 2026-08-09.
        anchors { leftMargin: Theme.gutter - 10; rightMargin: Theme.gutter }
        // top:346px — literal del prototipo (:114).
        y: 346
        // El bottom YA NO es el "52" literal del prototipo. Esa cifra
        // calzaba con SU footer, renderizado en su browser; el nuestro mide
        // otra cosa (childrenRect.height + 24 de padding, ui/Leyenda.qml) y
        // con la tipografia de Qt terminaba mas chico — dejando un hueco
        // muerto entre el ultimo estante y el pie, reportado el 2026-08-09.
        // Referenciar el alto REAL del footer en vez de copiar su numero
        // es lo que la nota original ya decia que tenia que pasar ("los 52
        // de abajo son justo lo que ocupa la leyenda con su padding") — el
        // 52 nunca fue el numero en si, era una forma de decir "el alto del
        // footer". +10 de aire minimo entre el ultimo estante y el pie.
        height: parent.height - y - (footerLeyenda.height + 10)

        model: root.catalogo ? root.catalogo.estantes : []
        spacing: 18
        clip: true
        keyNavigationWraps: false

        // Declarativo y no en un Component.onCompleted: puesto por codigo, el
        // foco arrancaba en la barra igual (visto el 2026-08-06 — la leyenda
        // mostraba los atajos de la barra con una tarjeta enfocada). Con
        // `focus: true` el arbol lo resuelve al construirse, sin depender del
        // orden en que corran los onCompleted.
        focus: true

        // El estante enfocado arriba de todo, con el siguiente asomando.
        // 218: el alto real de Shelf (ver su comentario — diverge a
        // proposito de los 192 del prototipo).
        preferredHighlightBegin: 0
        preferredHighlightEnd: 218
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 300

        delegate: Shelf {
            width: estantes.width
            datos: modelData
            paths: root.paths
            accent: root.accent
            enfocado: ListView.isCurrentItem
            // Solo en modo ORDEN: en SELECCION el titulo del estante ya
            // cuenta la historia con el sufijo "· LETRA C" (Catalog.qml), y
            // mostrar ADEMAS "⇅ LETRA" ahi confundiria "ordenado por" con
            // "filtrado a", que en Seleccion no es lo mismo.
            chipOrden: (modelData.tipo === "catalogo" && root.catalogo
                        && root.catalogo.modo === 0)
                       ? "⇅ " + root.catalogo.criterios[root.catalogo.criterio]
                       : ""
            onActivado: root.abrirDetalle(game)
        }

        // sort-select-spec.md §Reseteo de navegación: cada vez que se aplica
        // un filtro por seleccion, el foco salta a estantes / estante que
        // muestra el resultado / columna 0. Qt.callLater porque el shelf de
        // destino puede no tener delegate instanciado en el mismo tick en
        // que cambia `catalogo.estantes` (el filtro nuevo es un array
        // distinto, ListView puede tardar un frame en reconstruir).
        Connections {
            target: root.catalogo
            function onFiltroAplicado() {
                if (!root.catalogo) return;
                estantes.focus = true;
                estantes.currentIndex = root.catalogo.indiceCatalogo;
                Qt.callLater(function() {
                    if (estantes.currentItem) estantes.currentItem.indice = 0;
                });
            }
        }

        // Vista previa SIN robar el foco. Distinto del jump de arriba: ahi
        // el usuario ya terminó de elegir un valor y quiere ver el
        // resultado (spec lo pide explícito, incluye mover el foco). Acá el
        // usuario sigue parado en la barra, probablemente por seguir
        // tocando otros controles (probar LETRA, después AÑO, después la
        // dirección) — moverle el foco a los estantes en cada tecla lo
        // saca de la barra a mitad de camino. `currentIndex` solo
        // desplaza/resalta el estante CATALOGO sin tocar `estantes.focus`
        // ni `barra.focus`: el usuario VE el efecto de lo que acaba de
        // cambiar sin perder su lugar en la barra.
        //
        // Bug real reportado el 2026-08-09: "el orden solo se aplica sobre
        // la sección en la que está posicionado el usuario" — CATÁLOGO
        // siempre reaccionaba (correcto, sort-select-spec.md §Efecto sobre
        // el catálogo), pero si el usuario no estaba mirando ESE estante
        // en particular, el cambio pasaba desapercibido.
        Connections {
            target: root.catalogo
            function onCriterioChanged() { estantes.currentIndex = root.catalogo.indiceCatalogo; }
            function onDireccionChanged() { estantes.currentIndex = root.catalogo.indiceCatalogo; }
            function onModoChanged() { estantes.currentIndex = root.catalogo.indiceCatalogo; }
        }
    }

    // -------------------------------------------------------------- leyenda
    // Centrada y sobre un degrade que la despega de las tarjetas, como el
    // prototipo (:345). Las listas son las suyas (:758-759) — incluida la
    // decision de NO nombrar B en los estantes: volver a la barra es ▲, y
    // gastar un renglon de leyenda en un atajo redundante es ruido.
    //
    // ALTO DERIVADO DEL CONTENIDO, no un numero fijo. El prototipo define
    // este bloque con `padding:12px` (:345) — el alto sale de lo que mida el
    // contenido MAS su padding, nunca al reves. Antes esto era `height: 52`,
    // un numero elegido a ojo que no salia de esa cuenta — corregido el
    // 2026-08-09. El numero exacto lo decide la fuente en tiempo real, no
    // una constante: es EL MISMO bloque de codigo que van a usar las otras
    // pantallas (Buscar es la 010, todavia no existe), asi que tiene que
    // funcionar igual sin importar que fuente termine cargando cada una.
    //
    // El padding real es 7 y no los 12 del prototipo: con la tipografia de
    // Qt la barra quedaba visiblemente mas gruesa que en el diseño (pedido
    // explicito, 2026-08-09). Sigue siendo padding derivado, solo cambia la
    // constante — el alto se acomoda solo si cambia la fuente.
    Rectangle {
        id: footerLeyenda
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: leyenda.height + 14    // 7px arriba + 7px abajo
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Theme.alpha("#06070c", 0.92) }
        }

        // FIJA: siempre los mismos cuatro atajos, sin importar la region
        // enfocada. El prototipo SI varia la leyenda por region (tabs:
        // 'Plataforma/Estantes/Buscar', shelves: 'Navegar/Detalle/Orden/
        // Buscar' — Pegasus Home.dc.html:756-759), pero es una decision de
        // producto explicita mantenerla constante: un jugador que aprende de
        // memoria "abajo dice Navegar/Detalle/Orden/Buscar" no quiere que la
        // frase le cambie el significado al mover el foco un casillero.
        Leyenda {
            id: leyenda
            anchors.centerIn: parent
            accent: root.accent
            atajos: [{ k: "◄ ► ▲ ▼", l: "Navegar" }, { k: "A", l: "Detalle" },
                     { k: "X", l: "Criterio" }, { k: "Y", l: "Buscar" }]
        }
    }

    // ----------------------------------------------------------------- foco
    // Solo llega lo que ningun ListView quiso: ▲ desde el primer estante, y
    // los atajos globales, que nadie mas mira.
    Keys.onPressed: {
        if (!root.teclas) return;

        // sort-select-spec.md §Atajo de teclado/joystick: "X = equivalente
        // al click en el Boton 2" — cicla el criterio dentro del set que
        // permite el modo actual. Ya NO abre ningun panel: el modo, el
        // Boton 3 y el chip de limpiar se navegan con foco direccional +
        // A, como cualquier boton de la barra (misma seccion del spec).
        if (root.teclas.esX(event) && root.catalogo) {
            root.catalogo.ciclarCriterio(1);
            event.accepted = true;
        }
        else if (root.teclas.esY(event)) { root.abrirBuscar(); event.accepted = true; }
        else if (root.teclas.esA(event) && !barra.activeFocus) {
            root.abrirDetalle(root.juego);
            event.accepted = true;
        }
        // "arriba" y esB comparten el mismo destino (subir a la barra) pero
        // NO son lo mismo: "arriba" es navegacion pura, sin salida posible.
        // esB es Escape/B, y Pegasus lo tiene RESERVADO — es la tecla con la
        // que se sale del theme o se abre su propio menu. Si esB se acepta
        // ACA incluso cuando la barra ya esta enfocada (arriba del todo, sin
        // nada a donde volver), el evento se consume sin hacer nada visible
        // y Pegasus nunca se entera de que se apreto Escape: quedaba
        // "bloqueada" para todo lo que no fuera este theme. Por eso esB
        // exige `!barra.activeFocus` — solo se come la tecla cuando de
        // verdad hay algo que hacer con ella. Bug real visto en Pegasus el
        // 2026-08-09; docs/plataforma-pegasus.md §2 documenta el resto de
        // predicados de api.keys pero no marcaba a Escape/B como reservada,
        // se agrega ahi tambien.
        else if (root.teclas.direccion(event) === "arriba") {
            barra.focus = true;
            event.accepted = true;
        }
        else if (root.teclas.esB(event) && !barra.activeFocus) {
            barra.focus = true;
            event.accepted = true;
        }
    }

}
