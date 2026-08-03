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

    // Cual de los dos botones tiene el foco. Es el mismo mecanismo que va a
    // usar DetailScreen para recorrer sus targets, probado en chico.
    property int botonIdx: 0

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

                Rectangle {
                    width: parent.width; height: 1
                    color: Theme.glassBorder
                }

                // --- chequeo de los atomos de ui/ ---
                // La caratula de aca ejercita la cadena de fallback de
                // CONVENCION #2.2 con datos reales: dino cae en boxFront,
                // mok no tiene boxFront y tiene que caer en poster, y TEST
                // MULTIFILE no tiene ningun asset y tiene que mostrar el
                // color-wash con el accent. Recorriendo los juegos se ven los
                // tres eslabones sin escribir un solo caso de prueba.
                Row {
                    spacing: 18

                    Item {
                        width: 100; height: 126
                        CoverImage {
                            id: portada
                            anchors.fill: parent
                            game: root.juego
                            accent: ricos.accent
                            accent2: ricos.accent2
                            variacion: root.idx
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        SectionLabel {
                            text: "CHEQUEO DE ATOMOS"
                            activo: true
                            accent: root.accent
                        }

                        Text {
                            color: Theme.textFaint
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.sizeMonoSm
                            // Se reporta el NOMBRE del asset, no un indice: el
                            // indice cuenta sobre la lista ya filtrada, asi
                            // que un juego sin boxFront reportaba "eslabon 1"
                            // cuando en realidad habia cargado el poster.
                            // Visto en Pegasus el 2026-08-02 con mok.
                            text: "caratula: " + portada.origen
                                  + (portada.mostrandoPlaceholder
                                     ? "  (ningun asset cargo)" : "")
                        }

                        Row {
                            spacing: 8
                            Chip {
                                clave: "AÑO"
                                // releaseYear vuelve 0 cuando no hay release:
                                // (medido 2026-08-02). El 0 es "sin dato", no
                                // el año cero - misma colision que rating.
                                valor: (root.juego && root.juego.releaseYear > 0)
                                       ? String(root.juego.releaseYear) : ""
                                accent: root.accent
                            }
                            Chip {
                                clave: "FORMATO"
                                // Desde x-formato, NUNCA desde mediaFor():
                                // esa funcion mira la coleccion y se equivoca
                                // en 4 de 5 (docs/mapeo-mockup-pegasus.md).
                                valor: (root.juego && root.juego.extra["formato"])
                                       ? String(root.juego.extra["formato"][0]) : ""
                                accent: root.accent
                            }
                        }

                        Row {
                            spacing: 12
                            Boton {
                                texto: "JUGAR"
                                glifo: "▶"
                                variant: "accent"
                                accent: root.accent
                                activo: root.botonIdx === 0
                            }
                            Boton {
                                texto: "VER DETALLE"
                                glifo: "▤"
                                variant: "glass"
                                accent: root.accent
                                activo: root.botonIdx === 1
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    color: Theme.textFaint
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.sizeMonoSm
                    font.letterSpacing: Theme.trackingLabel * Theme.sizeMonoSm
                    text: "◄ ►  RECORRER JUEGOS        ▲ ▼  MOVER EL FOCO"
                }
            }
        }
    }

    function diagnostico() {
        var out = [];

        // El singleton, el import de subcarpeta y el escalado del lienzo ya se
        // confirmaron el 2026-07-29 y quedaron anotados en
        // spec/features/005-theme-base/tasks.md #1. Repetirlos en pantalla
        // solo gasta alto: si esta funcion corre, los tres andan.
        out.push("lienzo " + Theme.canvasWidth + "x" + Theme.canvasHeight
                 + " esc " + stage.scale.toFixed(2)
                 + "   fuentes: " + (Theme.fuentesPropias ? "propias" : "del sistema"));
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
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            root.botonIdx = 1 - root.botonIdx;
            event.accepted = true;
            return;
        }
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
