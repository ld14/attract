// Pantalla de detalle: barra superior, columna izquierda (panel de caratula +
// JUGAR) y columna de informacion (titulo, chips, box art, sinopsis).
//
// La columna de la derecha (190px) NO es un detalle de layout: el handoff la
// pide asi, con el box art, el badge de FORMATO y la resena apilados. Por eso
// FORMATO no es un chip mas junto a AÑO/SISTEMA/GENERO — se me habia colado
// como chip en la primera version y se corrigio el 2026-08-02.
//
// FALTA, de la feature 006: el carrusel de revistas en la columna izquierda y
// el video de gameplay en el panel de caratula. El layout ya los espera.
//
// El orden de foco sale del prototipo (detailTargets): [JUGAR] y despues cada
// extra. El carrusel se mete en el medio cuando llegue la 006.

import QtQuick 2.0
import ".."
import "../core"
import "../ui"

FocusScope {
    id: root

    property var game: null
    property var paths: null

    readonly property color accent: datos.accent

    // Lo que el root necesita para armar el modelo del visor. El detalle sabe
    // QUE se pidio abrir; DocModel sabe COMO se arma.
    readonly property var datosDelJuego: datos

    // Las pestañas del visor salen de acá: el carrusel ya cargó cada revista.
    readonly property var etiquetasRevistas: carrusel.etiquetas

    signal volver()
    signal lanzar(var game)

    GameData {
        id: datos
        game: root.game
        paths: root.paths
    }

    // ---------------------------------------------------------------- barra
    Item {
        id: barra
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors { topMargin: 26; leftMargin: Theme.gutter; rightMargin: Theme.gutter }
        height: 34

        Boton {
            anchors.left: parent.left
            texto: "GALERIA"
            glifo: "◄"
            variant: "glass"
            accent: root.accent
            activo: false
            onActivado: root.volver()
        }

        Text {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            color: root.accent
            font.family: Theme.fontMono
            font.pixelSize: Theme.sizeMono
            font.letterSpacing: 0.08 * Theme.sizeMono
            text: {
                if (!root.game) return "";
                var col = (root.game.collections && root.game.collections.count > 0)
                          ? root.game.collections.get(0).name : "";
                var anio = root.game.releaseYear > 0
                           ? String(root.game.releaseYear) : "";
                var p = [col, anio].filter(function(s) { return s !== ""; });
                return p.length ? p.join("  ·  ") : "Sin Informacion";
            }
        }
    }

    // ------------------------------------------------- columna izquierda
    Column {
        id: izquierda
        anchors { top: barra.bottom; topMargin: 30 }
        anchors { left: parent.left; leftMargin: Theme.gutter }
        width: 280
        spacing: 16

        // El panel de caratula: video de gameplay cuando lo hay, caratula
        // cuando no. Se apaga al salir del detalle para que el gabinete no
        // acumule decoders.
        Item {
            id: cajaPanel
            width: parent.width
            height: 288

            Sombra { fuente: panelCaratula }

            VideoPanel {
                id: panelCaratula
                anchors.fill: parent
                game: root.game
                accent: datos.accent
                accent2: datos.accent2
                activo: root.foco === 1
                encendido: root.visible
            }

            // Redondeo: se aproxima con un marco del color del fondo, igual
            // que en las tarjetas del rail.
            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusCard
                color: "transparent"
                border.width: 3
                border.color: Theme.screen
            }

            FocusRing {
                accent: root.accent
                activo: root.foco === 1
                radio: Theme.radiusCard
            }
        }

        Boton {
            id: btnJugar
            width: parent.width
            texto: "JUGAR"
            glifo: "▶"
            variant: "accent"
            accent: root.accent
            activo: root.foco === 0
            onActivado: root.lanzar(root.game)
        }

        // El "margin-top:auto" del diseno: empuja el carrusel al pie de la
        // columna. Se calcula EN UN SOLO LUGAR y con un piso, para que el
        // carrusel no pueda treparse encima de JUGAR pase lo que pase con las
        // fuentes o con el alto de sus tapas.
        //
        // Antes el carrusel estaba anclado al fondo de la pantalla, aparte de
        // esta columna: dos bloques posicionados por separado que se cruzaban
        // por unos pixeles (visto en Pegasus el 2026-08-03, "NOTAS EN
        // REVISTAS" encima del boton). Es el mismo error que el espaciador de
        // GameCard y el hero de la libreria — cuando el layout lo calculo yo,
        // funciona hasta que cambia algo que no controlo.
        Item {
            width: 1
            height: Math.max(18,
                root.height - 62 - izquierda.y
                - cajaPanel.height - btnJugar.height - carrusel.implicitHeight
                - izquierda.spacing * 3)
        }

        MagazineCarousel {
            id: carrusel
            width: parent.width
            game: root.game
            paths: root.paths
            mags: datos.mags
            accent: root.accent
            activo: root.foco === 2
            onAbrir: root.abrirRevista(i)
        }
    }

    // -------------------------------------------------- columna de info
    Column {
        anchors { top: barra.bottom; topMargin: 30 }
        anchors { left: izquierda.right; leftMargin: 48 }
        anchors { right: derecha.left; rightMargin: 32 }
        spacing: 18

        Text {
            width: Math.min(parent.width, 600)
            height: 102                      // dos renglones a 51px
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            color: Theme.textBright
            font.family: Theme.fontDisplay
            font.bold: true
            lineHeight: 1.0
            verticalAlignment: Text.AlignBottom
            // clamp(34px, 4vw, 60px): sobre el lienzo fijo el termino del
            // medio da 51px, y el 34 es el PISO del clamp - el diseno ya
            // contemplaba que el titulo achicara.
            fontSizeMode: Text.Fit
            font.pixelSize: 51
            minimumPixelSize: 34
            text: root.game ? root.game.title : ""
        }

        // Los chips no desaparecen cuando falta el dato: muestran
        // "Sin Informacion" (§2.3). Chip centraliza esa regla.
        Flow {
            width: Math.min(parent.width, 600)
            spacing: 8

            Chip {
                clave: "AÑO"
                accent: root.accent
                valor: (root.game && root.game.releaseYear > 0)
                       ? String(root.game.releaseYear) : ""
            }
            Chip {
                clave: "SISTEMA"
                accent: root.accent
                valor: (root.game && root.game.collections
                        && root.game.collections.count > 0)
                       ? root.game.collections.get(0).name : ""
            }
            Chip {
                clave: "GENERO"
                accent: root.accent
                valor: (root.game && root.game.genre) ? root.game.genre : ""
            }
            Chip {
                clave: "JUG."
                accent: root.accent
                valor: (root.game && root.game.players > 0)
                       ? String(root.game.players) : ""
            }
            Chip {
                clave: "DEV"
                accent: root.accent
                valor: (root.game && root.game.developer) ? root.game.developer : ""
            }
        }

        SectionLabel {
            text: "SINOPSIS"
            activo: true
            accent: root.accent
        }

        Text {
            width: Math.min(parent.width, 600)
            wrapMode: Text.WordWrap
            color: Theme.textBody
            font.family: Theme.fontBody
            font.pixelSize: Theme.sizeBody
            lineHeight: 1.62
            text: (root.game && root.game.summary) ? root.game.summary
                                                   : "Sin Informacion"
        }
    }

    // ------------------------------------------- columna derecha (190px)
    // Box art + badge de FORMATO + resena, apilados. Es lo que pide el
    // handoff; no es una variante.
    Column {
        id: derecha
        anchors { top: barra.bottom; topMargin: 30 }
        anchors { right: parent.right; rightMargin: Theme.gutter }
        width: 190
        spacing: 14

        Item {
            width: parent.width
            height: 144

            CoverImage {
                id: boxart
                width: 108; height: 144
                anchors.horizontalCenter: parent.horizontalCenter
                game: root.game
                accent: datos.accent
                accent2: datos.accent2
            }

            // El badge en la esquina. Es TEXTO y no un icono por medio:
            // x-formato es un dato libre (PCB, GD-ROM, Diskette, Cartucho...)
            // y dibujar un icono por cada valor posible obligaria a mantener
            // un mapa que se desactualiza solo. Decidido en el LAB 0.3.
            Rectangle {
                anchors { right: boxart.right; bottom: boxart.bottom }
                anchors { rightMargin: -7; bottomMargin: -7 }
                width: badge.width + 14
                height: 22
                radius: Theme.radiusChip
                color: "#0e1016"
                border.width: 1
                border.color: Theme.alpha(Theme.textBright, 0.18)
                visible: badge.text !== ""

                Text {
                    id: badge
                    anchors.centerIn: parent
                    color: root.accent
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.letterSpacing: 0.06 * 9
                    text: (root.game && root.game.extra["formato"])
                          ? String(root.game.extra["formato"][0]) : ""
                }
            }
        }

        Column {
            width: parent.width
            spacing: 2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "FORMATO"
                color: Theme.textFaint
                font.family: Theme.fontMono
                font.pixelSize: 8
                font.letterSpacing: Theme.trackingLabel * 8
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                // Sin x-formato el renglon no desaparece (§2.3).
                text: (root.game && root.game.extra["formato"])
                      ? String(root.game.extra["formato"][0]) : "Sin Informacion"
                color: (root.game && root.game.extra["formato"])
                       ? Theme.textPrimary : Theme.textFaint
                font.family: Theme.fontMono
                font.pixelSize: 10
            }
        }

        ReviewCard {
            width: parent.width
            datos: datos
            accent: root.accent
        }
    }

    // ------------------------------------------------- contenido extra
    // Anclado abajo, como el margin-top:auto del diseno.
    ExtrasList {
        id: extras
        anchors { left: izquierda.right; leftMargin: 48 }
        anchors { bottom: parent.bottom; bottomMargin: 72 }
        datos: datos
        accent: root.accent
        // 0 = JUGAR, 1 = video, 2 = carrusel; de ahi, las tarjetas.
        foco: root.foco - 3
        onAbrir: root.abrirExtra(tipo)
    }

    // ---------------------------------------------------------------- foco
    //
    // LA REGLA DEL DETALLE, que el prototipo tenia solo para el carrusel y aca
    // se generaliza porque hacia falta:
    //
    //     IZQUIERDA/DERECHA mueve ENTRE targets.
    //     ARRIBA/ABAJO actua DENTRO del target enfocado.
    //
    // El handoff pide que los controles del video se revelen "por foco de
    // D-pad" pero no dice como se llega ahi sin romper el recorrido. Esta
    // regla lo resuelve y ademas le da al carrusel su comportamiento sin un
    // caso especial: el carrusel pasa de pagina con arriba/abajo porque es lo
    // que hace "actuar dentro" de un carrusel.
    //
    // Orden: [JUGAR] -> [video] -> [carrusel] -> [Hacks] -> [Manual]. JUGAR
    // primero aunque el video este arriba en pantalla: la accion principal se
    // enfoca al entrar, no un control secundario. El orden no es estrictamente
    // espacial en el prototipo tampoco (el carrusel esta a la izquierda y los
    // extras a la derecha).
    property int foco: 0
    readonly property int _targets: 5

    signal abrirExtra(string tipo)
    signal abrirRevista(int i)

    Keys.onPressed: {
        // El target enfocado tiene la primera oportunidad con las verticales.
        // Si no la usa, cae al recorrido horizontal de abajo.
        if (root.foco === 1 && panelCaratula.manejarTecla(event)) {
            event.accepted = true;
            return;
        }
        if (root.foco === 2 && carrusel.manejarTecla(event)) {
            event.accepted = true;
            return;
        }

        if (api.keys.isCancel(event)) {
            root.volver();
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            root.foco = Math.min(root._targets - 1, root.foco + 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.foco = Math.max(0, root.foco - 1);
            event.accepted = true;
        } else if (api.keys.isAccept(event)) {
            if (root.foco === 0) root.lanzar(root.game);
            else if (root.foco === 3 && datos.hayCheats) root.abrirExtra("cheats");
            else if (root.foco === 4 && datos.hayManual) root.abrirExtra("manual");
            event.accepted = true;
        }
    }
}
