// Pantalla de libreria: barra superior, hero del juego enfocado y el rail de
// caratulas abajo.
//
// EL PATRON DE FOCO ES EL DE UNA TV, NO EL DE UNA WEB (handoff §1): el primer
// toque sobre una tarjeta la ENFOCA, el segundo abre el detalle. Nunca se
// entra de una. En un gabinete con joystick, entrar al primer toque hace
// imposible recorrer la libreria.
//
// Las pastillas de filtro (TODOS / ARCADE / CONSOLA / FAVORITOS) se dibujan
// como el diseno manda pero NO filtran nada todavia: conectarlas a
// api.filters es otra feature (ver spec.md §Fuera de alcance).

import QtQuick 2.0
import ".."
import "../core"
import "../ui"

FocusScope {
    id: root

    property var paths: null

    // El juego enfocado y su accent, para que theme.qml tina el fondo.
    readonly property var juego: rail.currentItem ? rail.currentItem.game : null
    readonly property color accent: rail.currentItem ? rail.currentItem.accent
                                                     : Theme.accentNeutro

    property string wordmark: "SHINBOX"

    signal abrirDetalle(var game)
    signal lanzar(var game)

    GameData {
        id: datos
        game: root.juego
        paths: root.paths
    }

    // ---------------------------------------------------------------- barra
    Item {
        id: barra
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors { topMargin: 26; leftMargin: Theme.gutter; rightMargin: Theme.gutter }
        height: 30

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

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
                font.letterSpacing: Theme.trackingWide * 15
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "ARCADE"
                color: Theme.textFaint
                font.family: Theme.fontDisplay
                font.pixelSize: 15
                font.letterSpacing: Theme.trackingWide * 15
            }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 18

            Repeater {
                model: ["TODOS", "ARCADE", "CONSOLA", "FAVORITOS"]
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData
                    // Decorativas: la activa es siempre la primera hasta que
                    // se conecten a api.filters.
                    color: index === 0 ? root.accent : Theme.textFaint
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.sizeMono
                    font.letterSpacing: 0.08 * Theme.sizeMono
                }
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 18
                Rectangle {
                    width: 1; height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.glassBorder
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    id: reloj
                    color: Theme.textMuted
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.sizeMono
                    text: "--:--"

                    // El diseno lo actualiza cada 20s, no cada segundo: no hay
                    // segundero en pantalla, despertar cada segundo solo gasta.
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
            }
        }
    }

    // ----------------------------------------------------------------- hero
    Column {
        id: hero
        anchors { left: parent.left; leftMargin: Theme.gutter }
        anchors { bottom: rail.top; bottomMargin: 24 }
        width: 680
        spacing: 16

        Row {
            spacing: 14

            // pill del sistema: borde y texto en accent
            Chip {
                anchors.verticalCenter: parent.verticalCenter
                resaltado: true
                accent: root.accent
                valor: (root.juego && root.juego.collections
                        && root.juego.collections.count > 0)
                       ? root.juego.collections.get(0).name : ""
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.textMuted
                font.family: Theme.fontMono
                font.pixelSize: Theme.sizeMono
                text: {
                    if (!root.juego) return "";
                    var anio = root.juego.releaseYear > 0
                               ? String(root.juego.releaseYear) : "";
                    var gen = root.juego.genre || "";
                    var p = [anio, gen].filter(function(s) { return s !== ""; });
                    // Ningun bloque desaparece (§2.3): sin año ni genero, el
                    // renglon dice que no hay dato, no queda en blanco.
                    return p.length ? p.join("  ·  ") : "Sin Informacion";
                }
            }
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            color: Theme.textBright
            font.family: Theme.fontDisplay
            font.bold: true
            // clamp(44px, 6.4vw, 104px) con el lienzo fijo de 1280 colapsa a
            // 6.4% de 1280 = 82px (ADR-0016).
            font.pixelSize: 82
            lineHeight: 0.92
            text: root.juego ? root.juego.title : ""
        }

        Text {
            width: 560
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
            color: Theme.textBody
            font.family: Theme.fontBody
            font.pixelSize: Theme.sizeBody
            lineHeight: 1.55
            // summary lo escribe attract synopsis (ADR-0011). Sin el, el
            // bloque no desaparece: dice que no hay dato (§2.3).
            text: (root.juego && root.juego.summary) ? root.juego.summary
                                                     : "Sin Informacion"
        }

        Row {
            spacing: 26

            Boton {
                texto: "JUGAR"
                glifo: "▶"
                variant: "accent"
                accent: root.accent
                activo: root.accion === 0
                onActivado: root.lanzar(root.juego)
            }

            Boton {
                texto: "VER DETALLE"
                glifo: "▤"
                variant: "glass"
                accent: root.accent
                activo: root.accion === 1
                onActivado: root.abrirDetalle(root.juego)
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.textFaint
                font.family: Theme.fontMono
                font.pixelSize: Theme.sizeMono
                text: ("0" + (rail.currentIndex + 1)).slice(-2) + " / "
                      + ("0" + api.allGames.count).slice(-2)
            }
        }
    }

    // ----------------------------------------------------------------- rail
    ListView {
        id: rail
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        anchors { leftMargin: Theme.gutter; rightMargin: Theme.gutter; bottomMargin: 58 }
        height: 190          // 166 de la tarjeta + los 14 que sube al enfocarse

        orientation: ListView.Horizontal
        spacing: 16
        model: api.allGames
        focus: true
        keyNavigationWraps: false

        // StrictlyEnforceRange fija la tarjeta enfocada a 2 anchos + gaps del
        // borde izquierdo, o sea tercera desde la izquierda como pide el
        // diseno, y ListView clampea sola en los extremos.
        preferredHighlightBegin: 2 * (148 + 16)
        preferredHighlightEnd: 2 * (148 + 16) + 148
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: 300

        // Sin esto las tarjetas se recortan al subir y escalar al enfocarse.
        clip: false

        delegate: GameCard {
            game: model
            paths: root.paths
            variacion: index
            activo: ListView.isCurrentItem
            onActivado: {
                // Patron TV: si ya estaba enfocada, abre; si no, solo enfoca.
                if (rail.currentIndex === index) root.abrirDetalle(model);
                else rail.currentIndex = index;
            }
        }
    }

    // ---------------------------------------------------------------- foco
    // Izquierda/derecha recorren el rail; arriba/abajo mueven entre los dos
    // botones del hero. Enter activa lo que este enfocado.
    property int accion: 0      // 0 = JUGAR, 1 = VER DETALLE

    Keys.onPressed: {
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            root.accion = 1 - root.accion;
            event.accepted = true;
            return;
        }
        // api.keys.isAccept mapea el gamepad; Qt.Key_Return solo el teclado
        // y en el gabinete no hay teclado.
        if (api.keys.isAccept(event)) {
            if (root.accion === 0) root.lanzar(root.juego);
            else root.abrirDetalle(root.juego);
            event.accepted = true;
        }
    }
}
