// Pantalla de detalle: barra superior, columna izquierda (panel de caratula +
// JUGAR) y columna de informacion (titulo, chips, box art, sinopsis).
//
// INCOMPLETA A PROPOSITO. Falta lo que va abajo de la sinopsis: el bloque
// NOTA DE LA CRITICA (ReviewCard) y las tarjetas de CONTENIDO EXTRA
// (ExtrasList). Y el panel de caratula muestra la imagen estatica: el video
// de gameplay llega con la feature 006 y se enchufa ahi sin rehacer el
// layout.
//
// El orden de foco sale del prototipo (detailTargets): [JUGAR] y despues cada
// extra. El carrusel de revistas se mete en el medio cuando llegue la 006.

import QtQuick 2.0
import ".."
import "../core"
import "../ui"

FocusScope {
    id: root

    property var game: null
    property var paths: null

    readonly property color accent: datos.accent

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

        // Panel de caratula. En la 006 esto pasa a mostrar el video de
        // gameplay cuando hay assets.video, con la caratula de fondo cuando
        // no (CONVENCION §2.1 nota 2: nunca queda un hueco).
        Item {
            width: parent.width
            height: 288

            CoverImage {
                anchors.fill: parent
                game: root.game
                accent: datos.accent
                accent2: datos.accent2
            }

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusCard
                color: "transparent"
                border.width: 3
                border.color: Theme.screen
            }

            // Vineta para que el titulo se lea sobre cualquier caratula.
            Rectangle {
                anchors.fill: parent
                anchors.margins: 3
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.55; color: "transparent" }
                    GradientStop { position: 1.0; color: Theme.alpha(Theme.screen, 0.92) }
                }
            }

            Text {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                anchors.margins: 16
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                color: Theme.textBright
                font.family: Theme.fontDisplay
                font.bold: true
                font.pixelSize: Theme.sizePanelTitle
                lineHeight: 1.0
                text: root.game ? root.game.title.toUpperCase() : ""
            }
        }

        Boton {
            width: parent.width
            texto: "JUGAR"
            glifo: "▶"
            variant: "accent"
            accent: root.accent
            activo: root.foco === 0
            onActivado: root.lanzar(root.game)
        }
    }

    // -------------------------------------------------- columna de info
    Column {
        anchors { top: barra.bottom; topMargin: 30 }
        anchors { left: izquierda.right; leftMargin: 48 }
        anchors { right: parent.right; rightMargin: Theme.gutter }
        spacing: 18

        Text {
            width: Math.min(parent.width, 600)
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            color: Theme.textBright
            font.family: Theme.fontDisplay
            font.bold: true
            // clamp(34px, 4vw, 60px) sobre el lienzo fijo de 1280 = 51px.
            font.pixelSize: 51
            lineHeight: 1.0
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
            Chip {
                // Siempre desde x-formato, NUNCA desde mediaFor(): esa funcion
                // mira la coleccion y no el juego, y se equivoca en 4 de 5
                // (docs/mapeo-mockup-pegasus.md).
                clave: "FORMATO"
                accent: root.accent
                valor: (root.game && root.game.extra["formato"])
                       ? String(root.game.extra["formato"][0]) : ""
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

    // ---------------------------------------------------------------- foco
    // Por ahora solo JUGAR. Cuando entren ExtrasList y el carrusel, esto pasa
    // a recorrer [JUGAR] -> [carrusel] -> [cada extra], como detailTargets.
    property int foco: 0

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            root.volver();
            event.accepted = true;
        } else if (api.keys.isAccept(event)) {
            root.lanzar(root.game);
            event.accepted = true;
        }
    }
}
