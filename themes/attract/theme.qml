// ATTRACT — theme de produccion. ESQUELETO (feature 005, tarea 1).
//
// Todavia no dibuja la libreria ni el detalle: dibuja el lienzo, el fondo y
// un panel de diagnostico. Existe para responder UNA pregunta antes de que
// haya veinte componentes escritos encima:
//
//     ¿un theme de Pegasus soporta subcarpetas y un singleton via qmldir?
//
// Toda la arquitectura de spec/features/005-theme-base/plan.md lo asume. Si
// la respuesta es no, la salida es aplanar el arbol y reemplazar el singleton
// por un QtObject con id declarado aca — un cambio mecanico, pero mucho mas
// barato de hacer ahora que despues.
//
// SI PEGASUS DICE "Theme loading failed", bisecta en este orden:
//   1. agrega `import "."` arriba, junto a los otros imports. Si con eso
//      carga: el qmldir del directorio implicito no se estaba leyendo.
//   2. saca `import "ui"` y el bloque Background. Si con eso carga: el
//      problema son las subcarpetas, no el singleton.
//   3. saca el singleton: reemplaza cada Theme.algo por un valor literal. Si
//      con eso carga: el problema es el singleton, no las subcarpetas.
// Anota cual de los tres fue en spec/features/005-theme-base/tasks.md.
//
// Lo que este archivo NO hace todavia, a proposito: leer data.json (necesita
// core/Paths.qml, bloqueado por themes/experimentos/rutas-relativas.qml) y
// dibujar sombras o glows (bloqueado por graphical-effects.qml).

import QtQuick 2.0
import "ui"

FocusScope {
    id: root
    focus: true
    anchors.fill: parent

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
            width: 660
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

        // Los titulos, no solo el conteo: la primera corrida dio 6 juegos
        // donde los metadata declaran 5 bloques game: (4 en fixtures/arcade +
        // 1 en library/arcade). La sospecha es que allGames cuenta un juego
        // por CADA file:, y TEST MULTIFILE tiene dos. Si es asi, el rail de la
        // libreria mostraria el mismo juego repetido, y eso choca con ADR-0004
        // ("una sola pagina de informacion por familia"). Listar los titulos
        // lo responde sin adivinar.
        out.push("juegos   : " + api.allGames.count + "  (los metadata declaran 5)");
        for (var i = 0; i < api.allGames.count; i++) {
            var g = api.allGames.get(i);
            var nf = (g.files !== undefined && g.files.count !== undefined)
                     ? g.files.count : "?";
            out.push("  " + (i + 1) + ". " + g.title + "   [files: " + nf + "]");
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
