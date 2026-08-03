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

    // Se instancia UNA vez y baja por propiedad. No es singleton a proposito:
    // uno en subcarpeta necesita su propio qmldir y es el mecanismo del que
    // menos se sabe contra este binario (ver plan.md).
    Paths { id: paths }

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
            crtScanlines: true
        }

        LibraryScreen {
            id: libreria
            anchors.fill: parent
            paths: paths
            visible: root.pantalla === "library" && !lanzando.active
            focus: root.pantalla === "library" && !lanzando.active
            // Sin esto, el rail sigue comiendose las flechas desde atras
            // mientras el detalle esta arriba.
            enabled: visible

            onAbrirDetalle: {
                root.juegoDetalle = game;
                root.pantalla = "detail";
            }
            onLanzar: root.lanzar(game)
        }

        DetailScreen {
            id: detalle
            anchors.fill: parent
            paths: paths
            game: root.juegoDetalle
            visible: root.pantalla === "detail" && !lanzando.active
            focus: root.pantalla === "detail" && !lanzando.active
            enabled: visible

            onVolver: root.pantalla = "library"
            onLanzar: root.lanzar(game)
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
