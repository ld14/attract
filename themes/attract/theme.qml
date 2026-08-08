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
    readonly property bool crtScanlines: true

    Rectangle { anchors.fill: parent; color: Theme.screen }

    Item {
        id: stage
        width: Theme.canvasWidth
        height: Theme.canvasHeight
        anchors.centerIn: parent
        scale: Math.min(root.width / Theme.canvasWidth,
                        root.height / Theme.canvasHeight)

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
            visible: root.pantalla === "detail" && !lanzando.active && !ayuda.active
            focus: root.pantalla === "detail" && !lanzando.active && !visor.active && !trucos.active && !ayuda.active
            enabled: visible

            onVolver: root.pantalla = "library"
            onLanzar: root.lanzar(game)
            onAbrirRevista: root.abrirRevista(i)
            onAbrirExtra: {
                if (tipo === "manual") root.abrirManual();
                else if (tipo === "cheats") trucos.active = true;
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
            focus: active

            sourceComponent: DocumentViewer {
                modelo: root.modeloDoc
                accent: root.accent
                fondo: detalle
                revistas: root.pestanasRevistas
                revistaActual: root.magIdx
                focus: true
                onCerrar: root.cerrarVisor()
                onCambiarRevista: root.abrirRevista(i)
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

    // El carrusel ya cargo cada revista, asi que las pestañas salen de ahi con
    // el nombre limpio y el color de marca. Cargarlas de nuevo aca seria pedir
    // los mismos archivos dos veces.
    readonly property var pestanasRevistas: detalle.etiquetasRevistas

    function abrirRevista(i) {
        var ms = detalle.datosDelJuego ? detalle.datosDelJuego.mags : [];
        if (i < 0 || i >= ms.length) return;
        root.magIdx = i;
        root.refAbierta = ms[i].ref || "";
        // Si la revista ya estaba en cache, MagazineData ya esta "listo" y el
        // modelo se puede armar de una; si no, lo arma el onEstadoChanged.
        root.armarModeloRevista();
    }

    function armarModeloRevista() {
        if (revistaAbierta.estado !== "listo") return;
        var set = paths.setDe(root.juegoDetalle);
        root.modeloDoc = docModel.desdeRevista(revistaAbierta, set);
        visor.active = true;
    }

    function abrirManual() {
        if (!detalle.datosDelJuego || !detalle.datosDelJuego.hayManual) return;
        root.modeloDoc = docModel.desdeManual(detalle.datosDelJuego, paths,
                                              root.juegoDetalle);
        visor.active = true;
    }

    function cerrarVisor() {
        visor.active = false;
        root.refAbierta = "";
        root.modeloDoc = null;
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
