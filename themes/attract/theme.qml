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
// AHORA el panel sirve para otra cosa: es el chequeo de core/Paths.qml y
// core/GameData.qml. No hay framework de tests en QML, asi que la
// verificacion es abrir Pegasus, recorrer los juegos con las flechas y mirar
// que resuelve cada uno — incluidos los que NO son de ATTRACT, que son los
// que tienen que degradar sin romper nada.
//
// El accent del fondo ya sale de data.json de verdad (ADR-0013): al recorrer
// los juegos, la pantalla cambia de color con el color que cada uno declara,
// y cae al neutro en los que no declaran ninguno.
//
// Lo que este archivo NO hace todavia, a proposito: las dos pantallas, y
// dibujar sombras o glows (bloqueado por
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

    // El juego "enfocado". Cuando entre LibraryScreen esto lo va a manejar el
    // rail; por ahora se recorre con las flechas, que es exactamente el mismo
    // movimiento y por lo tanto la misma prueba.
    property int idx: 0
    property var juego: api.allGames.count > 0 ? api.allGames.get(idx) : null

    GameData {
        id: ricos
        game: root.juego
        paths: paths
    }

    // El accent YA NO es de prueba: sale de data.json (ADR-0013), con la
    // degradacion al neutro cuando el juego no tiene ninguno cargado.
    property color accent: ricos.accent

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
                    text: "◄ ►  RECORRER JUEGOS"
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
        // De aca para abajo es el chequeo de Paths.qml y GameData.qml. En QML
        // no hay framework de tests: la verificacion es recorrer los juegos y
        // mirar que resuelve cada uno, incluidos los que NO son de ATTRACT,
        // que son los que tienen que degradar sin romper nada.
        //
        // Lo que tiene que dar, con game_dirs apuntando a fixtures y library:
        //   EXPERIMENTO     set por basename (no tiene x-set), listo, 1 revista,
        //                   4 combos + 2 trucos, review con score
        //   sf2ce           set por x-set, listo, 1 revista (ref colgado),
        //                   manual de 4 pags, sin cheats, sin review
        //   mok (fixtures)  set por x-set, SIN-DATOS (no tiene data.json)
        //   TEST MULTIFILE  base OK sin ningun asset, SIN-DATOS
        //   Steam           base VACIA (path es un URI), SIN-DATOS
        // "sin-datos" no es un fallo: es la degradacion de CONVENCION #2.3.

        if (!root.juego) return out.join("\n") + "\nSin juegos.";

        out.push("juego " + (root.idx + 1) + " de " + api.allGames.count
                 + ": " + root.juego.title);
        out.push("");
        out.push("--- Paths ---");
        out.push("  set    : " + (paths.setDe(root.juego) || "(sin set)"));
        out.push("  base   : " + (paths.baseDe(root.juego) || "(vacia - degrada, OK)"));
        out.push("");
        out.push("--- GameData ---");
        out.push("  estado : " + ricos.estado);
        out.push("  accent : " + ricos.accent
                 + (ricos.datos && ricos.datos.accent ? "  (de data.json)" : "  (neutro - degrada)"));
        out.push("  revistas: " + (ricos.hayRevistas
                 ? ricos.mags.length + "  ref=" + ricos.mags[0].ref
                 : "no  -> \"Sin cobertura en revistas\""));
        out.push("  cheats : " + (ricos.hayCheats
                 ? ricos.combosCount + " combos, " + ricos.codesCount + " trucos"
                 : "no  -> \"No Disponible\""));
        out.push("  manual : " + (ricos.hayManual
                 ? ricos.manualPaginas + " pags"
                 : "no  -> \"No Disponible\""));
        if (!ricos.hayReview) {
            out.push("  review : no  -> \"Sin Informacion\" (bloque entero)");
        } else {
            out.push("  review : score=" + (ricos.review.score !== undefined
                     ? ricos.review.score : "-"));
            // Las seis de CONVENCION #2.1 nota 3. Una resena parcial muestra
            // "-" en las que faltan, no oculta el bloque.
            var cats = ["originalidad", "graficos", "adiccion",
                        "sonido", "dificultad", "animacion"];
            var linea = "";
            for (var c = 0; c < cats.length; c++) {
                var v = ricos.catDe(cats[c]);
                linea += cats[c].substring(0, 4) + "=" + (v === null ? "-" : v) + " ";
            }
            out.push("           " + linea);
        }
        return out.join("\n");
    }

    Keys.onPressed: {
        if (api.allGames.count === 0) return;
        if (event.key === Qt.Key_Right) {
            root.idx = (root.idx + 1) % api.allGames.count;
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.idx = (root.idx - 1 + api.allGames.count) % api.allGames.count;
            event.accepted = true;
        }
    }
}
