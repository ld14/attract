// ATTRACT — theme de produccion. ESQUELETO (feature 005).
//
// Todavia no dibuja la libreria ni el detalle: dibuja el lienzo, el fondo y
// un panel de diagnostico.
//
// La pregunta que existia para responder ya esta respondida (2026-07-29,
// contra Pegasus real): SI, un theme de Pegasus soporta subcarpetas y un
// singleton via qmldir. El arbol de spec/features/005-theme-base/plan.md va
// tal como esta.
//
// AHORA el panel sirve para otra cosa: es el chequeo de core/Paths.qml. No
// hay framework de tests en QML, asi que la verificacion es abrir Pegasus y
// mirar que resuelve Paths para cada juego que encontro — incluidos los que
// NO son de ATTRACT, que son los que tienen que degradar sin romper nada.
//
// Lo que este archivo NO hace todavia, a proposito: leer data.json (falta
// core/GameData.qml) y dibujar sombras o glows (bloqueado por
// themes/experimentos/graphical-effects.qml, sin correr).

import QtQuick 2.0
import "ui"
import "core"

FocusScope {
    id: root
    focus: true
    anchors.fill: parent

    // Se instancia UNA vez y baja por id. No es singleton a proposito, ver
    // spec/features/005-theme-base/plan.md.
    Paths { id: paths }

    // El accent es por juego (ADR-0013). Todavia no hay GameData, asi que se
    // rota a mano con las flechas para ver el fondo reaccionar — es lo mismo
    // que va a pasar al mover el foco en el rail de la libreria.
    property var accentsDePrueba: ["#3ad17a", "#ff5a3c", "#9b6bff", "#4b8cff", "#ffb020"]
    property int accentIdx: 0
    property color accent: accentsDePrueba[accentIdx]

    Rectangle { anchors.fill: parent; color: Theme.screen }

    // -----------------------------------------------------------------
    // El lienzo fijo (ADR-0016): 1280x720 exactos, escalado entero.
    // Todo lo de adentro son constantes en pixeles, tomadas del diseno.
    // -----------------------------------------------------------------
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

        // --- panel de diagnostico (se va cuando entren las pantallas) ---
        Rectangle {
            anchors.centerIn: parent
            width: 780
            height: contenido.height + 44
            radius: Theme.radiusPanel
            color: Theme.alpha(Theme.screen, 0.82)
            border.width: 1
            border.color: Theme.alpha(root.accent, 0.45)

            Column {
                id: contenido
                anchors.centerIn: parent
                width: parent.width - 44
                spacing: 14

                Row {
                    spacing: 14
                    Rectangle {
                        width: 13; height: 13; radius: 3
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.accent
                    }
                    Text {
                        text: "ATTRACT"
                        color: Theme.textPrimary
                        font.family: Theme.fontDisplay
                        font.bold: true
                        font.pixelSize: 15
                        font.letterSpacing: Theme.trackingWide * 15
                    }
                    Text {
                        text: "ESQUELETO"
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.textFaint
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.sizeMono
                    }
                }

                Rectangle {
                    width: parent.width; height: 1
                    color: Theme.glassBorder
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: Theme.textBody
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.sizeLabel
                    lineHeight: 1.45
                    textFormat: Text.PlainText
                    text: root.diagnostico()
                }

                Text {
                    width: parent.width
                    color: Theme.textFaint
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.sizeMonoSm
                    font.letterSpacing: Theme.trackingLabel * Theme.sizeMonoSm
                    text: "◄ ►  CAMBIAR ACCENT"
                }
            }
        }
    }

    function diagnostico() {
        var out = [];

        // Si esta funcion corre, las dos cosas de abajo ya son verdad: el
        // singleton resolvio (se leyo Theme.canvasWidth) y la subcarpeta
        // resolvio (se instancio Background). No hace falta chequearlas, hace
        // falta DECIRLAS, para que quede anotado que se verificaron.
        out.push("singleton Theme (qmldir) : OK");
        out.push("import \"ui\" (subcarpeta): OK");
        out.push("");
        out.push("lienzo   : " + Theme.canvasWidth + "x" + Theme.canvasHeight
                 + "  escala " + stage.scale.toFixed(3));
        out.push("ventana  : " + Math.round(root.width) + "x" + Math.round(root.height));
        out.push("");

        if (Theme.fuentesPropias) {
            out.push("fuentes  : propias (fonts/*.ttf cargaron)");
        } else {
            out.push("fuentes  : DEL SISTEMA - falta bajar los .ttf");
            out.push("           ver fonts/README.md");
        }
        out.push("  display: " + Theme.fontDisplay);
        out.push("  body   : " + Theme.fontBody);
        out.push("  mono   : " + Theme.fontMono);
        out.push("");
        out.push("accent   : " + root.accent + "  (de prueba, todavia no sale de data.json)");
        out.push("");

        // Este bloque es el chequeo de Paths.qml: no hay framework de tests en
        // QML, asi que la verificacion es ver que resuelve para CADA juego que
        // Pegasus encontro, incluidos los que no son de ATTRACT.
        //
        // Lo que tiene que pasar:
        //   dino            -> set por basename (no tiene x-set) + base OK
        //   sf2ce, mok      -> set por x-set + base OK
        //   TEST MULTIFILE  -> base OK aunque no tenga NINGUN asset
        //   Steam           -> base VACIA (path es "steam:255710", no una ruta)
        // Una base vacia no es un fallo: es la degradacion de CONVENCION #2.3.
        out.push("juegos   : " + api.allGames.count);
        for (var i = 0; i < api.allGames.count; i++) {
            var g = api.allGames.get(i);
            out.push("  " + (i + 1) + ". " + g.title);
            out.push("      set : " + (paths.setDe(g) || "(sin set)"));
            out.push("      base: " + (paths.baseDe(g) || "(vacia - degrada, OK)"));
        }
        return out.join("\n");
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Right) {
            root.accentIdx = (root.accentIdx + 1) % root.accentsDePrueba.length;
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.accentIdx = (root.accentIdx - 1 + root.accentsDePrueba.length)
                             % root.accentsDePrueba.length;
            event.accepted = true;
        }
    }
}
