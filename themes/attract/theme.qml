// ATTRACT — theme de produccion. Raiz.
//
// Sostiene tres cosas y nada mas: el lienzo fijo (ADR-0016), el fondo, y que
// pantalla esta arriba. Todo lo demas vive en screens/ y ui/.
//
// EL FOCO LO RESUELVE EL ARBOL, no una cadena de ifs. El prototipo tenia un
// onKey(e) global con un if por estado (docs/mockup-referencia.html:752-778);
// en QML cada FocusScope maneja sus teclas y el que esta activo se lleva el
// foco. Menos estado que sincronizar y ningun bug de "la tecla se la comio la
// pantalla de atras".
//
// Verificado contra Pegasus real: subcarpetas y singleton via qmldir andan
// (2026-07-29), y Paths/GameData/atomos resuelven bien (2026-08-02). El
// detalle de cada corrida esta en spec/features/005-theme-base/tasks.md.

import QtQuick 2.0
import "core"
import "screens"
import "overlays"
import "ui"

FocusScope {
    id: root
    focus: true
    anchors.fill: parent

    // Se instancian UNA vez y bajan por propiedad. No son singletons a
    // proposito: uno en subcarpeta necesita su propio qmldir y es el mecanismo
    // del que menos se sabe contra este binario (ver plan.md).
    Paths { id: paths }
    Teclas { id: teclas }

    // El catalogo vive ACA y no dentro de la libreria porque Buscar (010) va a
    // recorrer el mismo pool: dos duenos del mismo catalogo serian dos
    // ordenamientos de 1200 juegos y dos verdades sobre que esta filtrado.
    Catalog { id: catalogo }

    // Alias con OTRO nombre, no `catalogo`/`teclas` a secas. Bug real visto
    // en Pegasus el 2026-08-09 (log: "QML SortPanel: Binding loop detected
    // for property catalogo/teclas", theme.qml:182): el Loader `orden` de
    // mas abajo escribe `sourceComponent: SortPanel { catalogo: catalogo }`,
    // y como `sourceComponent` con un objeto inline lo envuelve en un
    // Component implicito, ahi el nombre de la PROPIEDAD de SortPanel
    // (tambien `catalogo`) le gana al `id: catalogo` de aca arriba — se
    // autorreferencia en vez de apuntar a este objeto, y SortPanel se queda
    // con `catalogo: null` para siempre. `BrowseScreen { catalogo: catalogo }`
    // no tiene el problema porque es un hijo directo, no vive dentro de un
    // Loader.sourceComponent. Con un alias de nombre DISTINTO la ambiguedad
    // no puede pasar, sea cual sea el mecanismo exacto de scoping.
    readonly property var catalogoInstancia: catalogo
    readonly property var teclasInstancia: teclas

    // "library" | "detail"
    property string pantalla: "library"

    // El juego que se esta mirando: el enfocado en la libreria, o el elegido
    // al entrar al detalle.
    property var juegoDetalle: null
    readonly property var juegoActual: pantalla === "detail" ? juegoDetalle
                                                             : libreria.juego

    // El accent tine el fondo entero y sale de data.json (ADR-0013).
    readonly property color accent: pantalla === "detail" ? detalle.accent
                                                          : libreria.accent

    // Unico interruptor del filtro de tubo (prop `crtScanlines` del handoff,
    // default ON). Solo apaga la CAPA 4: las scanlines de ambiente de la capa 2
    // son independientes y siguen siempre encendidas — es lo que mantiene vivo
    // el fondo con el tubo apagado (background-texture-spec.md:10).
    //
    // Se apaga mientras el visor de documentos esta activo (revista O manual,
    // el mismo visor para los dos): la textura estorba la lectura de una
    // pagina escaneada, que ya trae su propio grano de escaneo — dos texturas
    // encima no suman, restan legibilidad. Tambien mientras la galeria esta
    // abierta: las piezas multimedia se ven nubladas por las scanlines.
    readonly property bool crtScanlines: !visor.active && !galeria.active

    Rectangle { anchors.fill: parent; color: Theme.screen }

    // EL LIENZO CRECE EN EL EJE QUE SOBRA — ADR-0019 (revision final).
    //
    // Las tres formulas de scale que se probaron antes fallan todas en una
    // pantalla que no sea 16:9 exacto, y la del Mac es 16:10 (2880x1800 =
    // 1.6, no 1.778 — medido sobre una captura real el 2026-08-09):
    //
    //   MIN(w/1280, h/720)      -> barras negras en el eje que sobra
    //   MAX(w/1280, h/720)      -> recorta contenido en el eje que sobra
    //   xScale/yScale separados -> deforma todo lo que no sea 16:9
    //
    // Ninguna sirve porque las tres asumen que el lienzo mide 1280x720 FIJO
    // y solo discuten como encajarlo. La salida es dejar de asumirlo: el
    // `scale` es MIN (nunca recorta, nunca deforma) pero el Item se
    // DIMENSIONA para cubrir la ventana entera en unidades de lienzo. En
    // 16:10 eso da 1280x800: los 720 del diseño mas 80 de aire real, que
    // los bloques anclados al borde (barra arriba, leyenda abajo, banda de
    // estantes) reparten solos porque ya estaban anclados, no posicionados
    // a mano.
    //
    // LO QUE ESTO NO CAMBIA, y es lo que mantiene vivo a ADR-0016: cada
    // medida de adentro sigue siendo la constante en pixeles del diseño
    // (tarjeta 148x166, gutter 48, tipografias). No se re-derivo ninguna a
    // fraccion del padre. Lo unico que cambia es CUANTO espacio hay
    // alrededor de esas constantes.
    Item {
        id: stage

        // MIN: la escala que hace entrar el lienzo entero sin recortar ni
        // deformar. Depende de root.width/height, nunca de stage.* — si
        // leyera su propio tamaño seria un binding loop.
        readonly property real escala:
            Math.min(root.width / Theme.canvasWidth,
                     root.height / Theme.canvasHeight)

        // La ventana entera, expresada en unidades de lienzo. Uno de los dos
        // da exactamente canvasWidth/canvasHeight y el otro da MAS — nunca
        // menos, que es lo que garantiza que el diseño siempre entre.
        width: root.width / escala
        height: root.height / escala

        anchors.centerIn: parent
        scale: escala

        Background {
            anchors.fill: parent
            accent: root.accent
        }

        BrowseScreen {
            id: libreria
            anchors.fill: parent
            paths: paths
            teclas: teclas
            catalogo: catalogo
            // `orden` (el popover de valor) NO va en `visible`: a diferencia
            // de ayuda/trucos/visor —modales de verdad, que tapan la pantalla
            // a proposito— este es un popover flotante, y el spec lo pide
            // explicito: "Sin scrim: el prototipo no oscurece nada detras del
            // popover" (overlays/SortPanel.qml). Con `!orden.active` tambien
            // en `visible`, Home se apagaba ENTERA en vez de quedar dibujada
            // detras — bug real visto en Pegasus el 2026-08-09. `enabled` y
            // `focus` SI se quedan con `orden.active`: Home se sigue viendo,
            // pero deja de reaccionar al teclado mientras el popover esta
            // arriba.
            visible: root.pantalla === "library" && !lanzando.active && !visor.active && !trucos.active && !ayuda.active
            focus: root.pantalla === "library" && !lanzando.active && !visor.active && !ayuda.active && !orden.active
            // Sin esto, los estantes siguen comiendose las flechas desde atras
            // mientras el detalle esta arriba.
            enabled: root.pantalla === "library" && !lanzando.active && !visor.active && !trucos.active && !ayuda.active && !orden.active

            onAbrirDetalle: {
                root.juegoDetalle = game;
                root.pantalla = "detail";
            }
            onLanzar: root.lanzar(game)
            onAbrirAyuda: ayuda.active = true
            onAbrirOrden: orden.active = true
            onCerrarOrden: orden.active = false
            // Buscar es la fase 010. Hasta que exista, Y no hace nada — y eso
            // es mejor que un boton que promete y no cumple: la pastilla
            // BUSCAR de la barra ya esta dibujada porque es parte del diseño,
            // pero el atajo no miente si no hay a donde ir.
        }

        DetailScreen {
            id: detalle
            anchors.fill: parent
            paths: paths
            game: root.juegoDetalle
            visible: root.pantalla === "detail" && !lanzando.active && !ayuda.active && !galeria.active
            focus: root.pantalla === "detail" && !lanzando.active && !visor.active && !trucos.active && !ayuda.active && !aviso.active && !galeria.active
            enabled: visible

            onVolver: root.pantalla = "library"
            onLanzar: root.lanzar(game)
            onAbrirRevista: root.abrirRevista(i)
            onAbrirExtra: {
                if (tipo === "manual") root.abrirManual();
                else if (tipo === "cheats") trucos.active = true;
                else if (tipo === "galeria") galeria.active = true;
            }
            onAbrirAyuda: ayuda.active = true
        }

        // --- el visor de documentos: revistas Y manual, el mismo ---
        //
        // El modelo lo arma DocModel; el visor no sabe cual de los dos le
        // toco. La revista se lee ACA y no en el carrusel porque el visor
        // necesita TODAS sus paginas, no solo la tapa.
        MagazineData {
            id: revistaAbierta
            game: root.juegoDetalle
            paths: paths
            ref: root.refAbierta
        }

        Loader {
            id: visor
            anchors.fill: parent
            active: false
            // El aviso del PDF se abre ENCIMA del visor (se llega con X desde
            // adentro), asi que mientras esta arriba el visor suelta el foco.
            focus: active && !aviso.active

            sourceComponent: DocumentViewer {
                modelo: root.modeloDoc
                accent: root.accent
                fondo: detalle
                pestanas: root.pestanasActuales
                pestanaActual: root.pestanaIdxActual
                focus: true
                onCerrar: root.cerrarVisor()
                onCambiarPestana: root.cambiarPestanaVisor(i)
                onAbrirPdf: root.pedirAbrirPdf(url)
            }
        }

        Loader {
            id: trucos
            anchors.fill: parent
            active: false
            focus: active

            sourceComponent: CheatsOverlay {
                datos: detalle.datosDelJuego
                titulo: root.juegoDetalle ? root.juegoDetalle.title : ""
                accent: root.accent
                fondo: detalle
                focus: true
                onCerrar: trucos.active = false
            }
        }

        Loader {
            id: galeria
            anchors.fill: parent
            active: false
            focus: active

            sourceComponent: GalleryOverlay {
                piezas: detalle.datosDelJuego ? detalle.datosDelJuego.galeria : []
                titulo: root.juegoDetalle ? root.juegoDetalle.title : ""
                accent: root.accent
                fondo: detalle
                focus: true
                onCerrar: galeria.active = false
            }
        }

        // La ayuda se abre desde Libreria O Detalle (README del handoff:
        // "visible en toda pantalla donde exista esa barra"), asi que el
        // fondo a desenfocar depende de donde estemos parados — mismo
        // ternario que ya resuelve root.accent un poco mas arriba.
        Loader {
            id: ayuda
            anchors.fill: parent
            active: false
            focus: active

            sourceComponent: HelpOverlay {
                accent: root.accent
                fondo: root.pantalla === "detail" ? detalle : libreria
                focus: true
                onCerrar: ayuda.active = false
            }
        }

        Loader {
            id: orden
            anchors.fill: parent
            active: false
            focus: active

            sourceComponent: SortPanel {
                catalogo: root.catalogoInstancia
                teclas: root.teclasInstancia
                accent: root.accent
                focus: true
                // libreria.popoverOrdenAbierto tambien se sincroniza aca, no
                // solo en onCerrarOrden: el popover se puede cerrar de tres
                // formas distintas (B/X adentro, click afuera, elegir un
                // valor) y las tres emiten esta misma señal — un solo lugar
                // que las cubra a las tres.
                onCerrar: {
                    orden.active = false;
                    libreria.popoverOrdenAbierto = false;
                }
            }
        }

        // Los overlays van en un Loader: cerrados no cuestan nada, y al
        // activarse se llevan el foco sin que nadie tenga que quitarselo a la
        // pantalla de atras.
        Loader {
            id: lanzando
            anchors.fill: parent
            active: false
            focus: active

            sourceComponent: LaunchOverlay {
                game: root.juegoLanzado
                accent: root.accent
                focus: true
                onCerrar: lanzando.active = false
            }
        }

        // El mismo overlay, en sus otros dos modos: preguntar antes de abrir el
        // PDF, y avisar si el sistema lo rechazo (ADR-0021). Va DESPUES de
        // `lanzando` para quedar por encima del visor y del detalle.
        Loader {
            id: aviso
            anchors.fill: parent
            active: false
            focus: active

            sourceComponent: LaunchOverlay {
                accent: root.accent
                modo: root.avisoModo
                focus: true

                titulo: root.avisoModo === "error" ? "NO SE PUDO ABRIR"
                                                   : "SE ABRE FUERA DE ATTRACT"
                encabezado: "MANUAL DIGITALIZADO"
                detalle: root.avisoDetalle
                nota: root.avisoModo === "error"
                      ? "Verificá que el PDF exista y que haya una aplicación instalada para abrirlo."
                      : "El manual se abre en el visor de PDF del sistema, fuera de ATTRACT. Para volver hay que cerrar esa ventana."

                onAceptar: root.abrirPdfConfirmado()
                onCerrar: root.cerrarAviso()
            }
        }

        // El filtro de tubo va ULTIMO y por encima de TODO — barra, tarjetas,
        // ayuda, trucos, visor y el popover de orden
        // (background-texture-spec.md:37, z-index:80 en el prototipo).
        //
        // Ser el ultimo hermano ya alcanzaria para quedar arriba; el z explicito
        // es para que siga arriba si alguien agrega un hermano despues.
        CrtOverlay {
            anchors.fill: parent
            z: 80
            activo: root.crtScanlines
        }
    }

    // --- estado del visor ---
    property string refAbierta: ""      // que revista esta leyendo MagazineData
    property int magIdx: 0             // cual de las revistas del juego
    property var modeloDoc: null

    // El slug de `articles[].game` que trata sobre este juego, sacado de
    // `mags[].article` (ADR-0025). NO es el set de Pegasus: la revista usa un
    // slug editorial ("golden-axe") y el set de MAME es una abreviatura
    // historica ("goldnaxe"). Los une `attract mags` por coincidencia difusa y
    // deja el resultado escrito; el theme no re-adivina nada.
    // "" cuando el data.json se escribio a mano sin el campo, y ahi se cae al
    // set - que es lo correcto justamente cuando los dos coinciden.
    property string articuloAbierto: ""

    // "revista" | "manual" | "" - cual de los dos esta abierto ahora. Decide
    // que pestañas mostrar y que hace onCambiarPestana; las dos filas nunca
    // conviven (ADR-0023), asi que alcanza con saber cual de las dos es.
    property string visorModo: ""

    // El carrusel ya cargo cada revista, asi que las pestañas salen de ahi con
    // el nombre limpio y el color de marca. Cargarlas de nuevo aca seria pedir
    // los mismos archivos dos veces.
    readonly property var pestanasRevistas: detalle.etiquetasRevistas

    // Las pestañas que le tocan al visor AHORA, segun el modo. Un solo prop
    // (DocumentViewer.pestanas) sirve para los dos casos porque nunca se
    // muestran juntos.
    readonly property var pestanasActuales:
        root.visorModo === "manual"
            ? (detalle.datosDelJuego ? detalle.datosDelJuego.manualPestanas : [])
            : root.pestanasRevistas

    readonly property int pestanaIdxActual:
        root.visorModo === "manual"
            ? (detalle.datosDelJuego ? detalle.datosDelJuego.manualIdx : 0)
            : root.magIdx

    // El click en una pestaña no sabe si esta mirando revistas o manuales:
    // eso lo decide root.visorModo, una sola vez, aca.
    function cambiarPestanaVisor(i) {
        if (root.visorModo === "manual") root.abrirManualDoc(i);
        else root.abrirRevista(i);
    }

    function abrirRevista(i) {
        var ms = detalle.datosDelJuego ? detalle.datosDelJuego.mags : [];
        if (i < 0 || i >= ms.length) return;
        root.visorModo = "revista";
        root.magIdx = i;
        root.refAbierta = ms[i].ref || "";
        root.articuloAbierto = ms[i].article || "";
        // Si la revista ya estaba en cache, MagazineData ya esta "listo" y el
        // modelo se puede armar de una; si no, lo arma el onEstadoChanged.
        root.armarModeloRevista();
    }

    function armarModeloRevista() {
        if (revistaAbierta.estado !== "listo") return;
        // El slug escrito manda; sin el, el set (ver articuloAbierto).
        var slug = root.articuloAbierto !== ""
                   ? root.articuloAbierto
                   : paths.setDe(root.juegoDetalle);
        root.modeloDoc = docModel.desdeRevista(revistaAbierta, slug);
        visor.active = true;
    }

    // Un manual puede ser paginas escaneadas, un PDF, o las dos cosas
    // (ADR-0021), y un juego puede tener MAS DE UN documento (ADR-0023). Esta
    // es la PUERTA DE ENTRADA, desde la tarjeta.
    //
    // Con UN SOLO documento: si no tiene paginas, se salta el visor y el PDF
    // es lo unico que hay - mismo comportamiento que antes de la 0023.
    //
    // Con MAS DE UNO: SIEMPRE entra al visor, aunque el documento activo (el
    // primero, tras el reset de GameData) sea solo-PDF. Si saltara directo al
    // PDF como en el caso de uno solo, un juego que declaro su manual de
    // servicio ANTES que el de uso perderia toda forma de llegar a las
    // pestañas y ver el resto - la puerta de entrada no puede depender del
    // orden en que alguien escribio la lista.
    function abrirManual() {
        var d = detalle.datosDelJuego;
        if (!d || !d.hayManual) return;
        root.visorModo = "manual";

        if (!d.hayManualPaginas && d.manuales.length === 1) {
            root.pedirAbrirPdf(paths.manualPdfDe(root.juegoDetalle, d.manualPdf));
            return;
        }

        root.modeloDoc = docModel.desdeManual(d, paths, root.juegoDetalle);
        visor.active = true;
    }

    // Cambiar de pestaña ADENTRO del visor es distinto de la entrada: nunca
    // salta a pedir el PDF ni cierra el visor solo, aunque el documento
    // elegido no tenga paginas - "cambiar de pestaña no cierra el visor" es
    // un criterio explicito (spec 014). Si el documento no tiene paginas, el
    // visor las muestra como lo que son ("Página no disponible", el mismo
    // criterio que ya usa para una pagina individual rota) y el boton/tecla
    // X sigue ahi para que el USUARIO decida abrir el PDF, no automatico.
    function abrirManualDoc(i) {
        var d = detalle.datosDelJuego;
        if (!d || i < 0 || i >= d.manuales.length) return;
        d.manualIdx = i;
        root.modeloDoc = docModel.desdeManual(d, paths, root.juegoDetalle);
    }

    // --- el PDF del manual, que se abre AFUERA (ADR-0021) ---
    //
    // Se pregunta antes. En el gabinete abrirlo es un viaje de ida: se midio
    // que el visor de PDF aparece por delante y Pegasus PIERDE EL FOCO, y con
    // joystick solo no hay forma de volver. Preguntar no arregla el foco -no
    // hay ninguna API que lo haga- pero convierte una sorpresa en una decision.
    property string avisoModo: "confirmar"      // "confirmar" | "error"
    property string avisoDetalle: ""
    property string pdfPendiente: ""

    function pedirAbrirPdf(url) {
        if (!url) return;
        root.pdfPendiente = url;
        root.avisoDetalle = url;
        root.avisoModo = "confirmar";
        aviso.active = true;
    }

    function abrirPdfConfirmado() {
        var url = root.pdfPendiente;
        root.pdfPendiente = "";

        // Un false NO puede tumbar nada: se chequea el retorno y se cambia de
        // modo. Es el unico canal de error que existe, y se midio que existe.
        if (paths.abrirAfuera(url)) {
            aviso.active = false;
            // Si se entro directo por un manual solo-PDF (sin pasar por el
            // visor), root.visorModo quedo en "manual" sin nadie que lo baje.
            if (!visor.active) root.visorModo = "";
        } else {
            root.avisoModo = "error";
        }
    }

    function cerrarAviso() {
        aviso.active = false;
        root.pdfPendiente = "";
        if (!visor.active) root.visorModo = "";
    }

    function cerrarVisor() {
        visor.active = false;
        root.refAbierta = "";
        root.articuloAbierto = "";
        root.modeloDoc = null;
        root.visorModo = "";
    }

    // Solo para llamar a los constructores; no dibuja nada.
    DocModel { id: docModel }

    Connections {
        target: revistaAbierta
        onEstadoChanged: if (revistaAbierta.estado === "listo") root.armarModeloRevista()
    }

    property var juegoLanzado: null

    // Se muestra el overlay ANTES de lanzar: si Pegasus toma la pantalla,
    // fue el ultimo cuadro que se vio; si el lanzamiento falla -pasa, ver el
    // encabezado de LaunchOverlay- el overlay se cierra solo.
    function lanzar(game) {
        if (!game) return;
        root.juegoLanzado = game;
        lanzando.active = true;
        game.launch();
    }
}
